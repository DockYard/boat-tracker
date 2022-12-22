defmodule BoatVisualizer.NetCDF do
  @moduledoc """
  Loads a dataset in memory.
  """
  use Agent

  import Nx.Defn

  require Logger

  # times are measured in days, so 1 min = 1 / (24 * 60)
  @ten_minutes_in_mjd 10 / (24 * 60)
  @pi :math.pi()

  def start_link(%{dataset_filename: filename, start_date: start_date, end_date: end_date}) do
    {:ok, file} = NetCDF.File.open(filename)
    Logger.info("Loading NetCDF data")
    file_data = load(file)

    Logger.info("Getting speed and direction tensors")

    {speed, direction} =
      abs_and_direction_tensors(file_data.u, file_data.v, Nx.tensor(file_data.t.value))

    start_mjd = Cldr.Calendar.modified_julian_day(start_date)
    end_mjd = Cldr.Calendar.modified_julian_day(end_date)

    Logger.info("Interpolating values")

    {speed, direction, time_t} =
      filter_epoch_and_interpolate_to_seconds(
        speed,
        direction,
        file_data.t.value,
        start_mjd,
        end_mjd
      )

    lat_t = Nx.tensor(file_data.lat.value)
    lon_t = Nx.tensor(file_data.lon.value)

    Logger.info("Converting to GeoJSON-like data")
    geodata = render_data(speed, direction, lat_t, lon_t)

    Logger.info("Starting NetCDF Agent")

    Agent.start_link(
      fn ->
        %{geodata: geodata, time: time_t, epoch: start_mjd}
      end,
      name: __MODULE__
    )
  end

  @doc """
  Returns data for the requested timestamp and bounding box.
  """
  def get_geodata(
        time,
        min_lat,
        max_lat,
        min_lon,
        max_lon
      ) do
    Agent.get(__MODULE__, fn state ->
      time_idx =
        state.time
        |> Nx.less_equal(time)
        |> Nx.argmax(tie_break: :high)
        |> Nx.to_number()

      Logger.debug("time_idx: #{time_idx}")

      Enum.filter(state.geodata[time_idx], fn [lon, lat, _direction, _speed] ->
        lon >= min_lon and lon <= max_lon and lat >= min_lat and lat <= max_lat
      end)
    end)
  end

  @doc """
  Returns the start time for the file
  """
  def epoch do
    Agent.get(__MODULE__, & &1.epoch)
  end

  defp load(file) do
    # eastward velocity
    {:ok, u_var} = NetCDF.Variable.load(file, "u")
    # northward velocity
    {:ok, v_var} = NetCDF.Variable.load(file, "v")
    # time
    {:ok, t_var} = NetCDF.Variable.load(file, "time")
    # latitude - latc and lonc index the u and v variables
    {:ok, lat_var} = NetCDF.Variable.load(file, "latc")
    # longitude
    {:ok, lon_var} = NetCDF.Variable.load(file, "lonc")

    %{u: u_var, v: v_var, t: t_var, lat: lat_var, lon: lon_var}
  end

  defp abs_and_direction_tensors(u_var, v_var, t) do
    time_size = Nx.size(t)
    shape = {time_size, :auto}

    u = Nx.tensor(u_var.value, type: u_var.type) |> Nx.reshape(shape)
    v = Nx.tensor(v_var.value, type: v_var.type) |> Nx.reshape(shape)
    abs_and_direction_tensors_n(u, v)
  end

  defnp abs_and_direction_tensors_n(u, v) do
    # We want to represent the direction as the angle where 0º is
    # "up" and 90º is "right". This is not the conventional "math"
    # angle, but its complement instead.

    # We can achieve these results by loading (u, v) as imaginary and
    # real parts of a complex number. This provides a way to easily calculate
    # the angles in the way we desire, because we can think of the resulting
    # numbers as vectors in a space where the x coordinate is the vertical axis
    # and the y coordinate is the horizontal axis, lining up with the definition
    # above.

    # This also avoids the issue where `Nx.atan2/2` wraps angles around due to domain
    # restrictions.

    complex_velocity = Nx.complex(v, u)

    speed = Nx.abs(complex_velocity)
    # convert m/s to knots
    speed_kt = speed * 1.94384

    direction_rad = Nx.phase(complex_velocity)

    direction_deg = direction_rad * 180 / @pi
    # Wrap the values so that they're constrained between 0º and 360º

    direction_deg = Nx.select(direction_deg < 0, direction_deg + 360, direction_deg)

    {speed_kt, direction_deg}
  end

  defp filter_epoch_and_interpolate_to_seconds(speed, direction, time, start_mjd, end_mjd) do
    {time, indices} =
      time
      |> Enum.with_index()
      |> Enum.filter(fn {t, _} -> start_mjd <= t and t <= end_mjd end)
      |> Enum.unzip()

    idx_tensor = Nx.tensor(indices)
    speed = Nx.take(speed, idx_tensor)
    direction = Nx.take(direction, idx_tensor)

    {indices, p_values} =
      time
      |> Enum.with_index()
      |> Enum.zip(tl(time))
      |> Enum.flat_map(fn {{t1, idx}, t2} ->
        dt_days = t2 - t1
        num_minutes = ceil(dt_days / @ten_minutes_in_mjd)

        # here we want to return pairs of idx and the respective p parameter
        # for the linear interpolation x0 * (1 - p) + x1 * p,
        # which is just p = n / num_minutes
        Enum.map(0..(num_minutes - 1), fn n ->
          {idx, n / num_minutes}
        end)
      end)
      |> Enum.unzip()

    indices = Nx.tensor(indices)
    p_values = Nx.tensor(p_values)

    Logger.debug("Interpolating speed")
    speed = interpolate(speed, indices, Nx.new_axis(p_values, 1))

    Logger.debug("Interpolating direction")
    direction = interpolate(direction, indices, Nx.new_axis(p_values, 1))

    Logger.debug("Interpolating time")
    time = interpolate(Nx.tensor(time) |> IO.inspect(), IO.inspect(indices), IO.inspect(p_values))

    IO.inspect(time, label: "time result")

    Logger.debug("Done interpolating")

    {speed, direction, time}
  end

  defn interpolate(tensor, indices, p) do
    x0 = Nx.take(tensor, indices)
    x1 = Nx.take(tensor, indices + 1)

    x0 * (1 - p) + x1 * p
  end

  defp render_data(speed, direction_deg, lat, lon) do
    lat = Nx.to_flat_list(lat)
    lon = Nx.to_flat_list(lon)

    n = Nx.axis_size(speed, 0) - 1
    Logger.debug("Max time index #{n}")

    for time <- 0..n, into: %{} do
      if rem(time, 50) == 0 do
        Logger.debug("Processing time index #{time}")
      end

      geojson = render_data(speed, direction_deg, lat, lon, time)
      {time, geojson}
    end
  end

  defp render_data(speed, direction_deg, lat, lon, time_index) do
    [
      lon,
      lat,
      Nx.to_flat_list(direction_deg[time_index]),
      Nx.to_flat_list(speed[time_index])
    ]
    |> Enum.zip_with(fn
      [_, _, _, speed] when speed == 0 ->
        # optimization because we don't render 0 speeds anyway
        nil

      data ->
        data
    end)
    |> Enum.filter(& &1)
  end
end

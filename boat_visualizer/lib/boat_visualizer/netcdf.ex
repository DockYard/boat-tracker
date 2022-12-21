defmodule BoatVisualizer.NetCDF do
  @moduledoc """
  Loads a dataset in memory.
  """
  use Agent

  require Logger

  def start_link(%{dataset_filename: filename}) do
    {:ok, file} = NetCDF.File.open(filename)
    Logger.info("Loading NetCDF data")
    file_data = load(file)

    time_t = Nx.tensor(file_data.t.value)

    Logger.info("Getting speed and direction tensors")
    {speed, direction} = abs_and_direction_tensors(file_data.u, file_data.v, time_t)

    lat_t = Nx.tensor(file_data.lat.value)
    lon_t = Nx.tensor(file_data.lon.value)

    Logger.info("Converting to GeoJSON-like data")
    geodata = render_data(speed, direction, lat_t, lon_t)

    Logger.info("Starting NetCDF Agent")

    Agent.start_link(
      fn ->
        %{geodata: geodata, time: time_t}
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

      Enum.filter(state.geodata[time_idx], fn [lon, lat, _direction, _speed] ->
        lon >= min_lon and lon <= max_lon and lat >= min_lat and lat <= max_lat
      end)
    end)
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
    speed_kt = Nx.multiply(speed, 1.94384)

    direction_rad = Nx.phase(complex_velocity)

    direction_deg = Nx.multiply(direction_rad, 180 / :math.pi())
    # Wrap the values so that they're constrained between 0º and 360º
    direction_deg =
      Nx.select(Nx.less(direction_deg, 0), Nx.add(direction_deg, 360), direction_deg)

    {speed_kt, direction_deg}
  end

  defp render_data(speed, direction_deg, lat, lon) do
    lat = Nx.to_flat_list(lat)
    lon = Nx.to_flat_list(lon)

    for time <- 0..(Nx.axis_size(speed, 0) - 1), into: %{} do
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
        unless Enum.any?(data, &(&1 == :nan)) do
          data
        end
    end)
    |> Enum.filter(& &1)
  end
end

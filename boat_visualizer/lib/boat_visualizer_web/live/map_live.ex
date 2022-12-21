defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias BoatVisualizer.Animation
  alias BoatVisualizer.Coordinates

  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(BoatVisualizer.PubSub, "leaflet")
    [initial_coordinates | _] = coordinates = Coordinates.get_coordinates("trip-01.csv")
    map_center = Coordinates.get_center(coordinates)

    Animation.set_track_coordinates(coordinates)
    Animation.set_map_view(map_center)
    Animation.set_marker_coordinates(initial_coordinates)

    {now, us} = NaiveDateTime.utc_now() |> NaiveDateTime.to_gregorian_seconds()
    now = now + us / 1_000_000

    min_lat = 42.1666
    max_lat = 42.4093
    min_lon = -71.0473
    max_lon = -70.8557

    socket =
      socket
      |> assign(:current_coordinates, initial_coordinates)
      |> assign(:coordinates, coordinates)
      |> assign(:map_center, map_center)
      |> assign(:current_position, 0)
      |> assign(:max_position, Enum.count(coordinates) - 1)
      |> assign(:show_track, true)
      |> assign(:last_event_sent_at, now)
      |> assign(:bounding_box, %{
        "min_lat" => min_lat,
        "min_lon" => min_lon,
        "max_lat" => max_lat,
        "max_lon" => max_lon
      })

    {:ok, socket}
  end

  def handle_event("change_bounds", %{"bounds" => bounding_box}, %{assigns: assigns} = socket) do
    {:reply, %{ok: true}, assign(socket, :bounding_box, bounding_box)}
  end

  def handle_event("set_position", event_data, %{assigns: assigns} = socket) do
    {throttle, new_position} =
      case event_data["position"] do
        nil ->
          {false, assigns.current_position}

        pos ->
          {true, String.to_integer(pos)}
      end

    new_coordinates = Enum.at(assigns.coordinates, new_position)
    Animation.set_marker_position(new_position)

    # epoch for fixed dataset is from 59898.0 to 59904.0
    # 10751 is the max value for position

    {now, us} = NaiveDateTime.utc_now() |> NaiveDateTime.to_gregorian_seconds()
    now = now + us / 1_000_000
    diff = now - assigns.last_event_sent_at

    {last_event_sent_at, current_data} =
      if (throttle and diff > 0.25) or not throttle do
        Logger.debug("[diff=#{diff}] Sending current data event")
        {time, _, _} = new_coordinates
        {t0, _, _} = Enum.at(assigns.coordinates, 0)
        milliseconds_diff = NaiveDateTime.diff(time, t0, :millisecond)
        time = BoatVisualizer.NetCDF.epoch() + milliseconds_diff / (24 * :timer.hours(1))

        %{
          "min_lat" => min_lat,
          "min_lon" => min_lon,
          "max_lat" => max_lat,
          "max_lon" => max_lon
        } = assigns.bounding_box

        data = BoatVisualizer.NetCDF.get_geodata(time, min_lat, max_lat, min_lon, max_lon)

        Logger.debug("size=#{data |> Jason.encode!() |> byte_size()}")

        {now, data}
      else
        Logger.debug("[diff=#{diff}] Not sending current data event")
        {assigns.last_event_sent_at, nil}
      end

    socket =
      socket
      |> assign(:current_position, new_position)
      |> assign(:current_coordinates, new_coordinates)
      |> assign(:last_event_sent_at, last_event_sent_at)

    socket =
      if current_data do
        push_event(socket, "add_current_markers", %{current_data: current_data})
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("clear", _, socket), do: {:noreply, push_event(socket, "clear_polyline", %{})}

  def handle_event("toggle_track", _, %{assigns: %{show_track: value}} = socket) do
    {:noreply,
     socket
     |> assign(:show_track, !value)
     |> push_event("toggle_track", %{value: !value})}
  end

  # def handle_event("update_currents", _, %{assigns: assigns} = socket) do
  # end

  def handle_info({"track_coordinates", coordinates}, socket) do
    {:noreply, push_event(socket, "track_coordinates", %{coordinates: coordinates})}
  end

  def handle_info({"marker_position", position}, socket) do
    {:noreply, push_event(socket, "marker_position", %{position: position})}
  end

  def handle_info({event, latitude, longitude}, socket) do
    {:noreply, push_event(socket, event, %{latitude: latitude, longitude: longitude})}
  end

  defp print_coordinates({datetime, latitude, longitude}),
    do:
      "#{NaiveDateTime.to_string(datetime)} [#{Float.round(latitude, 4)}, #{Float.round(longitude, 4)}]"
end

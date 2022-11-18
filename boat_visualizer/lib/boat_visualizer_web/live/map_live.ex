defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias BoatVisualizer.Animation
  alias BoatVisualizer.Coordinates

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(BoatVisualizer.PubSub, "leaflet")
    [initial_coordinates | _] = coordinates = Coordinates.get_coordinates("trip-01.csv")
    map_center = Coordinates.get_center(coordinates)

    Animation.set_track_coordinates(coordinates)
    Animation.set_map_view(map_center)
    Animation.set_marker_coordinates(initial_coordinates)

    {:ok,
     socket
     |> assign(:current_coordinates, initial_coordinates)
     |> assign(:coordinates, coordinates)
     |> assign(:map_center, map_center)
     |> assign(:current_position, 0)
     |> assign(:max_position, Enum.count(coordinates) - 1)
     |> assign(:show_track, true)}
  end

  def handle_event("set_position", %{"position" => position}, %{assigns: assigns} = socket) do
    new_position = String.to_integer(position)
    new_coordinates = Enum.at(assigns.coordinates, new_position)
    Animation.set_marker_position(new_position)

    {:noreply,
     socket
     |> assign(:current_position, new_position)
     |> assign(:current_coordinates, new_coordinates)}
  end

  def handle_event("clear", _, socket), do: {:noreply, push_event(socket, "clear_polyline", %{})}

  def handle_event("toggle_track", _, %{assigns: %{show_track: value}} = socket) do
    {:noreply,
     socket
     |> assign(:show_track, !value)
     |> push_event("toggle_track", %{value: !value})}
  end

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

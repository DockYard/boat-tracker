defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias BoatVisualizer.Coordinates
  alias BoatVisualizer.Animation

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(BoatVisualizer.PubSub, "leaflet")
    [initial_coordinates | _] = coordinates = Coordinates.get_coordinates("trip-01.csv")
    map_center = Coordinates.get_center(coordinates)
    Animation.set_map_view(map_center)

    {:ok,
     socket
     |> assign(:current_coordinates, initial_coordinates)
     |> assign(:coordinates, coordinates)
     |> assign(:map_center, map_center)}
  end

  def render(assigns) do
    ~H"""
    <div id="map" phx-update="ignore"></div>
    """
  end

  def handle_info({"set_map_view", latitude, longitude}, socket),
    do:
      {:noreply, push_event(socket, "set_map_view", %{latitude: latitude, longitude: longitude})}

  def handle_info({"set_marker_coordinates", latitude, longitude}, socket),
    do: {:noreply, push_event(socket, "coordinates", %{latitude: latitude, longitude: longitude})}
end

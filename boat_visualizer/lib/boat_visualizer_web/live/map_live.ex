defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  alias BoatVisualizer.Coordinates

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(BoatVisualizer.PubSub, "markers")
    [initial_coordinates | _] = coordinates = Coordinates.get_coordinates("trip-01.csv")
    map_center = Coordinates.get_center(coordinates)

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

  def handle_info({latitude, longitude}, socket),
    do: {:noreply, push_event(socket, "coordinates", %{latitude: latitude, longitude: longitude})}
end

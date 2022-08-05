defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(BoatVisualizer.PubSub, "markers")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="map" phx-update="ignore"></div>
    """
  end

  def handle_info({latitude, longitude}, socket),
    do: {:noreply, push_event(socket, "coordinates", %{latitude: latitude, longitude: longitude})}
end

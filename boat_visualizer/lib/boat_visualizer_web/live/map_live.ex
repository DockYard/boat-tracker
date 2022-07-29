defmodule BoatVisualizerWeb.MapLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div id="map" phx-update="ignore"></div>
    """
  end
end

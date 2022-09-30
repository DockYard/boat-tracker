defmodule BoatVisualizer.Animation do
  alias Phoenix.PubSub

  @initial_coordinates {42.27, -70.997}
  @step_increment 0.00005
  @timeout 1000

  def set_map_view({latitude, longitude}),
    do: PubSub.broadcast(BoatVisualizer.PubSub, "leaflet", {"set_map_view", latitude, longitude})

  def diagonal({lat, lng} \\ @initial_coordinates) do
    updated_coordinates = {lat + @step_increment, lng + @step_increment}
    PubSub.broadcast(BoatVisualizer.PubSub, "leaflet", updated_coordinates)
    Process.sleep(@timeout)

    diagonal(updated_coordinates)
  end
end

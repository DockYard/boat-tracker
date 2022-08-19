defmodule BoatVisualizer.Animation do
  alias Phoenix.PubSub

  @initial_coordinates {42.27, -70.997}
  @step_increment 0.00005
  @timeout 1000

  def diagonal({lat, lng} \\ @initial_coordinates) do
    updated_coordinates = {lat + @step_increment, lng + @step_increment}
    PubSub.broadcast(BoatVisualizer.PubSub, "markers", updated_coordinates)
    Process.sleep(@timeout)

    diagonal(updated_coordinates)
  end
end

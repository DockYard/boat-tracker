defmodule BoatVisualizer.Animation do
  alias Phoenix.PubSub

  @initial_coordinates {42.321, -71.12}
  @steps 100
  @step_increment 0.001
  @timeout 50

  def diagonal(coordinates \\ @initial_coordinates, current_step \\ 0)
  def diagonal(_coordinates, @steps), do: nil

  def diagonal({lat, lng}, step) do
    updated_coordinates = {lat + @step_increment, lng + @step_increment}
    PubSub.broadcast(BoatVisualizer.PubSub, "markers", updated_coordinates)
    Process.sleep(@timeout)

    diagonal(updated_coordinates, step + 1)
  end
end

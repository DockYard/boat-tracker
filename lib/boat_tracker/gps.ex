defmodule BoatTracker.GPS do
  use GenServer

  def start, do: GenServer.start_link(__MODULE__, nil)

  @impl true
  def init(state) do
    # TODO: Read and print coordinates

    {:ok, state}
  end
end

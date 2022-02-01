defmodule BoatTracker.GPS do
  use GenServer

  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @impl true
  def init(state) do
    # TODO: Read and print coordinates

    {:ok, state}
  end
end

defmodule BoatTracker.GPS do
  use GenServer

  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @impl true
  def init(state) do
    print_coordinates()

    {:ok, state}
  end

  @impl true
  def handle_info(:print, state) do
    print_coordinates()

    {:noreply, state}
  end

  defp print_coordinates do
    # TODO: Read coordinates

    IO.puts("printing for future coordinates!")
    Process.send_after(self(), :print, 1000)
  end
end

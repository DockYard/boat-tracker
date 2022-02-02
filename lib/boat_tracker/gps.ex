defmodule BoatTracker.GPS do
  use GenServer
  require Logger

  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @impl true
  def init(state) do
    log_coordinates()

    {:ok, state}
  end

  @impl true
  def handle_info(:print, state) do
    log_coordinates()

    {:noreply, state}
  end

  defp log_coordinates do
    # TODO: Read coordinates

    Logger.info("Logging for future coordinates!")
    Process.send_after(self(), :print, 1000)
  end
end

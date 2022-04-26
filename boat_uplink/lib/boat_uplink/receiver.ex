defmodule BoatUplink.Receiver do
  use GenServer
  require Logger

  def start_link(state), do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

  @impl true
  def init(_state) do
    pid = setup_LoRa()

    {:ok, pid}
  end

  # A message should be received on every 'send' since this is the process that started the link.
  @impl true
  def handle_info(msg, state) do
    Logger.info("Received data: #{inspect(msg)}")

    # Once data is received, the nmea sentence should be parsed.

    {:noreply, state}
  end

  defp setup_LoRa do
    {:ok, pid} = LoRa.start_link()
    :ok = LoRa.begin(pid, 433.0e6)
    :ok = LoRa.set_spreading_factor(pid, 8)
    :ok = LoRa.set_signal_bandwidth(pid, 62.5e3)

    pid
  end
end

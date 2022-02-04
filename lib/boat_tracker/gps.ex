defmodule BoatTracker.GPS do
  use GenServer
  require Logger

  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @impl true
  def init(state) do
    setup_UART()

    {:ok, state}
  end

  @impl true
  def handle_info({:circuits_uart, _serial_port_id, {:error, reason}}, state) do
    Logger.info("error: #{inspect(reason)}")

    {:noreply, state}
  end

  @impl true
  def handle_info({:circuits_uart, _serial_port_id, data}, state) do
    Logger.info("coordinates: #{inspect(data)}")

    {:noreply, state}
  end

  defp setup_UART do
    {:ok, pid} = Circuits.UART.start_link()

    :ok =
      Circuits.UART.open(pid, "ttyAMA0",
        speed: 9600,
        active: true,
        framing: {Circuits.UART.Framing.Line, separator: "\r\n"}
      )
  end
end

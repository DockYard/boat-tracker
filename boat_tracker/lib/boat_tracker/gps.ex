defmodule BoatTracker.GPS do
  use GenServer
  require Logger

  def start_link(state), do: GenServer.start_link(__MODULE__, state)

  @impl true
  def init(_) do
    {:ok, uart_pid} = setup_UART()
    {:ok, spi_ref} = setup_SPI()

    {:ok, {uart_pid, spi_ref}}
  end

  @impl true
  def handle_info({:circuits_uart, _serial_port_id, {:error, reason}}, state) do
    Logger.info("error: #{inspect(reason)}")

    {:noreply, state}
  end

  @impl true
  def handle_info({:circuits_uart, _, "$GPRMC" <> _sentence = data}, {_, ref} = state) do
    Logger.info("coordinates: #{inspect(data)}")

    case Circuits.SPI.transfer(ref, data) do
      {:ok, sent_data} -> Logger.info("sending: #{inspect(sent_data)}")
      {:error, reason} -> Logger.info("sending error: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  def handle_info({:circuits_uart, _serial_port_id, _data}, state), do: {:noreply, state}

  defp setup_UART do
    {:ok, pid} = Circuits.UART.start_link()

    :ok =
      Circuits.UART.open(pid, "ttyAMA0",
        speed: 9600,
        active: true,
        framing: {Circuits.UART.Framing.Line, separator: "\r\n"}
      )

    {:ok, pid}
  end

  defp setup_SPI, do: Circuits.SPI.open("spidev0.0", speed_hz: 300_000)
end

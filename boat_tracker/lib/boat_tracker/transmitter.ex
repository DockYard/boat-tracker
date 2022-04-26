defmodule BoatTracker.Transmitter do
  use GenServer
  require Logger
  alias Circuits.UART.Framing.Line

  def start_link(state), do: GenServer.start_link(__MODULE__, state, name: __MODULE__)

  @impl true
  def init(_) do
    uart_pid = setup_UART()
    lora_pid = setup_LoRa()

    {:ok, {uart_pid, lora_pid}}
  end

  @impl true
  def handle_info({:circuits_uart, _serial_port_id, {:error, reason}}, state) do
    Logger.info("error: #{inspect(reason)}")

    {:noreply, state}
  end

  @impl true
  def handle_info({:circuits_uart, _, "$GPRMC" <> _sentence = data}, {_, lora_pid} = state) do
    Logger.info("sending: #{inspect(data)}")
    LoRa.send(lora_pid, data)

    {:noreply, state}
  end

  def handle_info({:circuits_uart, _serial_port_id, _data}, state), do: {:noreply, state}

  defp setup_UART do
    {:ok, pid} = Circuits.UART.start_link()

    :ok =
      Circuits.UART.open(pid, "ttyAMA0",
        speed: 9600,
        active: true,
        framing: {Line, separator: "\r\n"}
      )

    pid
  end

  defp setup_LoRa do
    frequency = get_frequency()

    {:ok, pid} = LoRa.start_link()
    :ok = LoRa.begin(pid, frequency)
    :ok = LoRa.set_spreading_factor(pid, 8)
    :ok = LoRa.set_signal_bandwidth(pid, 62.5e3)

    pid
  end

  defp get_frequency do
    "LORA_FREQUENCY"
    |> System.get_env("915.0e6")
    |> String.to_float()
  end
end
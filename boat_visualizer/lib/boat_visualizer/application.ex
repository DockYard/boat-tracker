defmodule BoatVisualizer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BoatVisualizer.Repo,
      # Start the Telemetry supervisor
      BoatVisualizerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BoatVisualizer.PubSub},
      # Start the Endpoint (http/https)
      {BoatVisualizer.NetCDF,
       %{
         dataset_filename: Path.join(:code.priv_dir(:boat_visualizer), "dataset_20221221.nc"),
         start_date: ~D[2022-12-21],
         end_date: ~D[2022-12-23]
       }},
      BoatVisualizerWeb.Endpoint
      # Start a worker by calling: BoatVisualizer.Worker.start_link(arg)
      # {BoatVisualizer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BoatVisualizer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BoatVisualizerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

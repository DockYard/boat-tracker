defmodule BoatVisualizer.Repo do
  use Ecto.Repo,
    otp_app: :boat_visualizer,
    adapter: Ecto.Adapters.Postgres
end

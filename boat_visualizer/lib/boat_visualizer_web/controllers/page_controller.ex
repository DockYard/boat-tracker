defmodule BoatVisualizerWeb.PageController do
  use BoatVisualizerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule WarWeb.PageController do
  use WarWeb, :controller
  import Phoenix.LiveView.Controller
  alias War.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    case GameSupervisor.create_game(1) do
      {:ok, pid} ->
        conn
        |> put_session("game_pid", pid)
        |> put_flash(:info, "ID is #{inspect(pid)}")
        |> live_render(WarWeb.GameLive, session: %{"game_pid" => pid})

      {:error, _error} ->
        put_view(conn, PageView)
        |> render("error.html", message: "Couldn't start a game")
    end
  end

  def play(conn, %{"pid" => p} = _params) do
    conn
    |> live_render(WarWeb.GameLive, session: %{"game_pid" => p})
  end
end

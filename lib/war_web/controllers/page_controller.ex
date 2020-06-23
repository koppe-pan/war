defmodule WarWeb.PageController do
  use WarWeb, :controller
  import Phoenix.LiveView.Controller
  alias War.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    id = War.generate_id()

    case GameSupervisor.create_game(id) do
      {:ok, pid} ->
        Process.register(pid, String.to_atom(id))

        conn
        |> put_session("game_pid", pid)
        |> clear_flash()
        |> put_flash(:info, "ID is " <> id)
        |> live_render(WarWeb.GameLive, session: %{"game_pid" => pid})

      {:error, _error} ->
        put_view(conn, PageView)
        |> render("error.html", message: "Couldn't start a game")
    end
  end

  def play(conn, %{"pid_atom" => p} = _params) do
    pid =
      p
      |> String.to_atom()
      |> Process.whereis()

    conn
    |> clear_flash()
    |> live_render(WarWeb.GameLive, session: %{"game_pid" => pid})
  end
end

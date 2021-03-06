defmodule WarWeb.GameLive do
  use WarWeb, :live_view

  alias War.{Game, GameSupervisor, GameMonitor}

  @tick 300

  @impl true
  def mount(_params, %{"_csrf_token" => token, "game_pid" => pid} = _session, socket) do
    Game.initialize_board(pid, token)

    game = GameSupervisor.state(pid)

    socket =
      if token == game.white do
        socket |> assign(color: "white")
      else
        socket |> assign(color: "black")
      end
      |> assign(pid: pid, selected_square: nil, tick: @tick, tick_move: 0)
      |> update_assigns_from_game()

    if connected?(socket) do
      {:ok,
       socket
       |> schedule_tick()}
    else
      {:ok, socket}
    end
  end

  def handle_event(
        "square-clicked",
        %{"number" => n},
        %{assigns: %{selected_square: nil}} = socket
      ) do
    {:noreply, assign(socket, selected_square: String.to_integer(n))}
  end

  def handle_event("square-clicked", %{"number" => n}, %{assigns: %{selected_square: m}} = socket) do
    if(m == String.to_integer(n)) do
      {:noreply, assign(socket, selected_square: nil)}
    else
      {:noreply, assign(socket, selected_square: String.to_integer(n))}
    end
  end

  def handle_event("update-state", %{"id_for_state" => i, "state" => s}, socket) do
    id = String.to_integer(i)

    socket.assigns[:pid]
    |> Game.update_state(socket.assigns[:color], id, s)

    {:noreply, socket}
  end

  def handle_event("update-direction", %{"id_for_direction" => i, "direction" => d}, socket) do
    id = String.to_integer(i)

    socket.assigns[:pid]
    |> Game.update_direction(socket.assigns[:color], id, d)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_socket =
      socket
      |> update_assigns_from_game()
      |> schedule_tick()

    {:noreply, new_socket}
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp update_assigns_from_game(socket = %{assigns: %{tick_move: 600}}) do
    socket
    |> assign(tick_move: 0)
    |> update_assigns_from_game
  end

  defp update_assigns_from_game(socket = %{assigns: %{tick_move: tick_move}}) do
    game =
      socket.assigns[:pid]
      |> GameSupervisor.state()

    socket =
      socket
      |> check_finish(game)

    Game.update_dead(socket.assigns[:pid])
    Game.update_seen(socket.assigns[:pid])
    Game.update_hp(socket.assigns[:pid])

    Game.update_position(socket.assigns[:pid], tick_move)

    socket
    |> assign(tick_move: tick_move + 1)
    |> assign_pieces(game)
    |> assign_enemies(game)
    |> assign_detail(game)
  end

  defp check_finish(socket, game) do
    cond do
      Game.win_color(game) == socket.assigns[:color] ->
        finish_game(socket.assigns[:pid], socket.assigns[:color])

        socket
        |> redirect(
          to:
            Routes.page_path(WarWeb.Endpoint, :result,
              monitor_pid: GameMonitor.get_pid(socket.assigns[:pid]),
              result: "Win",
              color: socket.assigns[:color]
            )
        )

      Game.win_color(game) == opponent_color(socket) ->
        finish_game(socket.assigns[:pid], socket.assigns[:color])

        socket
        |> redirect(
          to:
            Routes.page_path(WarWeb.Endpoint, :result,
              monitor_pid: GameMonitor.get_pid(socket.assigns[:pid]),
              result: "Lose",
              color: socket.assigns[:color]
            )
        )

      true ->
        socket
    end
  end

  defp assign_pieces(socket, game) do
    p =
      game
      |> Map.get(my_board(socket))
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v ->
        {v.id, v.position, v.state, v.hp, v.ap, v.attack_area, v.search_area, div(600, v.speed)}
      end)
      |> Enum.sort()

    assign(socket, pieces: p)
  end

  defp assign_enemies(socket, game) do
    p =
      game
      |> Map.get(opponent_board(socket))
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.filter(fn v -> v.seen? end)
      |> Enum.map(fn v -> {v.position, v.hp <= 10} end)
      |> Enum.sort()

    c =
      game
      |> Map.get(opponent_board(socket))
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.count()

    assign(socket, enemies: p, enemies_count: c)
  end

  defp assign_detail(%{assigns: %{selected_square: nil}} = socket, _game) do
    assign(socket, detail: nil)
  end

  defp assign_detail(%{assigns: %{selected_square: id}} = socket, game) do
    g =
      game
      |> Map.get(my_board(socket))
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.find(fn v -> v.id == id end)

    if is_nil(g) do
      assign(socket, detail: nil)
    else
      d = %{
        id: g.id,
        position: %{file: elem(g.position, 0), rank: elem(g.position, 1)},
        state: g.state,
        direction: g.direction
      }

      assign(socket, detail: d)
    end
  end

  defp my_board(socket) do
    ("board_" <> socket.assigns[:color])
    |> String.to_atom()
  end

  defp opponent_board(socket) do
    ("board_" <> opponent_color(socket))
    |> String.to_atom()
  end

  defp opponent_color(socket) do
    if socket.assigns[:color] == "white" do
      "black"
    else
      "white"
    end
  end

  defp finish_game(pid, color) do
    pid
    |> GameMonitor.stop_monitoring()
    |> Game.finish(color)
    |> GameSupervisor.stop_game(GameSupervisor.state(pid))
  end
end

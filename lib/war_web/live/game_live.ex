defmodule WarWeb.GameLive do
  use WarWeb, :live_view

  alias War.{Game, GameSupervisor}

  @impl true
  def mount(_params, %{"game_pid" => pid} = _session, socket) do
    socket =
      socket
      |> assign(id: pid, selected_square: nil)
      |> update_assigns_from_game(GameSupervisor.state(pid))

    {:ok, socket}
  end

  def handle_event("square-clicked", %{"id" => n}, %{assigns: %{selected_square: n}} = socket) do
    {:noreply, assign(socket, selected_square: nil)}
  end

  def handle_event("square-clicked", %{"id" => n}, %{assigns: %{selected_square: nil}} = socket) do
    {:noreply, assign(socket, selected_square: n)}
  end

  def handle_info(%Game{} = game, socket) do
    {:noreply, update_assigns_from_game(socket, game)}
  end

  defp update_assigns_from_game(socket, game) do
    socket
    |> assign_pieces(game)
    |> assign_detail(game)
  end

  defp assign_pieces(socket, game) do
    p =
      game
      |> Map.get(:board)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn g -> {g.id, g.color, g.position} end)
      |> Enum.sort()

    assign(socket, pieces: p)
  end

  defp assign_detail(%{assigns: %{selected_square: nil}} = socket, _game) do
    assign(socket, detail: nil)
  end

  defp assign_detail(%{assigns: %{selected_square: id}} = socket, game) do
    g =
      game
      |> Map.get(:board)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.find(fn g -> g.id == id end)

    d = {g.id, g.position, g.state, g.direction}
    assign(socket, detail: d)
  end
end

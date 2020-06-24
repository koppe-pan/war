defmodule War.Game do
  @moduledoc """
  Game server
  """
  use GenServer

  alias War.Game

  defstruct id: nil,
            white: nil,
            black: nil,
            board_white: [],
            board_black: []

  @width 8
  @depth 8
  @near 1

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def init(id) do
    {:ok, %__MODULE__{id: id}}
  end

  def initialize_board(pid, token) do
    GenServer.cast(pid, {:initialize_board, token})
  end

  def update_state(pid, "black", id, state) do
    GenServer.cast(pid, {:update_state, {"black", id, state}})
  end

  def update_state(pid, "white", id, state) do
    GenServer.cast(pid, {:update_state, {"white", id, state}})
  end

  def update_direction(pid, "black", id, direction) do
    GenServer.cast(pid, {:update_direction, {"black", id, direction}})
  end

  def update_direction(pid, "white", id, direction) do
    GenServer.cast(pid, {:update_direction, {"white", id, direction}})
  end

  def update_position(pid, tick_move) do
    GenServer.cast(pid, {:update_move, tick_move})
  end

  def update_seen(pid) do
    GenServer.cast(pid, :update_seen)
  end

  def update_dead(pid) do
    GenServer.cast(pid, :update_dead)
  end

  def update_hp(pid) do
    GenServer.cast(pid, :update_hp)
  end

  def win_color(game) do
    if is_nil(game.black) do
      ""
    else
      cond do
        Enum.all?(game.board_white, fn v -> v.seen? end) or Enum.empty?(game.board_white) ->
          "black"

        Enum.all?(game.board_black, fn v -> v.seen? end) or Enum.empty?(game.board_black) ->
          "white"

        true ->
          ""
      end
    end
  end

  def finish(pid, color) do
    GenServer.cast(pid, {:finish, color})
  end

  def handle_cast({:initialize_board, token}, game = %Game{white: nil, black: nil}) do
    {:noreply,
     game
     |> Map.replace!(:white, token)}
  end

  def handle_cast({:initialize_board, token}, game = %Game{white: token, black: nil}) do
    {:noreply, game}
  end

  def handle_cast({:initialize_board, token}, game = %Game{white: _white, black: nil}) do
    generated_white =
      0..7
      |> Enum.map(fn key ->
        if rem(key, 2) == 0 do
          attacker_white(key)
        else
          searcher_white(key)
        end
      end)

    generated_black =
      0..7
      |> Enum.map(fn key ->
        if rem(key, 2) == 0 do
          attacker_black(key)
        else
          searcher_black(key)
        end
      end)

    {:noreply,
     game
     |> Map.replace!(:black, token)
     |> Map.replace!(:board_white, generated_white)
     |> Map.replace!(:board_black, generated_black)}
  end

  def handle_cast({:initialize_board, token}, game = %Game{white: _, black: token}) do
    {:noreply, game}
  end

  def handle_cast({:initialize_board, _token}, _game) do
    {:error, "two players have already entrered"}
  end

  def handle_cast({:update_state, {"black", id, state}}, game) do
    replaced =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_state(v, id, state) end)

    {:noreply, Map.replace!(game, :board_black, replaced)}
  end

  def handle_cast({:update_state, {"white", id, state}}, game) do
    replaced =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_state(v, id, state) end)

    {:noreply, Map.replace!(game, :board_white, replaced)}
  end

  def handle_cast({:update_direction, {"black", id, direction}}, game) do
    replaced =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_direction(v, id, direction) end)

    {:noreply, Map.replace!(game, :board_black, replaced)}
  end

  def handle_cast({:update_direction, {"white", id, direction}}, game) do
    replaced =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_direction(v, id, direction) end)

    {:noreply, Map.replace!(game, :board_white, replaced)}
  end

  def handle_cast(:update_hp, game) do
    replaced_white =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_hp(v, game.board_black) end)

    replaced_black =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_hp(v, game.board_white) end)

    {:noreply,
     game
     |> Map.replace!(:board_white, replaced_white)
     |> Map.replace!(:board_black, replaced_black)}
  end

  def handle_cast(:update_dead, game) do
    replaced_white =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_dead(v) end)

    replaced_black =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.map(fn v -> replace_dead(v) end)

    {:noreply,
     game
     |> Map.replace!(:board_white, replaced_white)
     |> Map.replace!(:board_black, replaced_black)}
  end

  def handle_cast(:update_seen, game) do
    replaced_white =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_seen(v, game.board_black) end)

    replaced_black =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_seen(v, game.board_white) end)

    {:noreply,
     game
     |> Map.replace!(:board_white, replaced_white)
     |> Map.replace!(:board_black, replaced_black)}
  end

  def handle_cast({:update_move, tick_move}, game) do
    replaced_white =
      game
      |> Map.get(:board_white)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_move(v, tick_move) end)

    replaced_black =
      game
      |> Map.get(:board_black)
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> replace_move(v, tick_move) end)

    {:noreply,
     game
     |> Map.replace!(:board_white, replaced_white)
     |> Map.replace!(:board_black, replaced_black)}
  end

  def handle_cast({:finish, color}, game) do
    c = String.to_atom(color)
    {:noreply, Map.replace!(game, c, "finished")}
  end

  defp replace_state(board = %{id: id}, id, state) do
    board
    |> Map.replace!(:state, state)
  end

  defp replace_state(board, _id, _state) do
    board
  end

  defp replace_direction(board = %{id: id}, id, direction) do
    board
    |> Map.replace!(:direction, direction)
  end

  defp replace_direction(board, _id, _direction) do
    board
  end

  defp replace_hp(board, opponent) do
    damage =
      opponent
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> how_damaged(board.position, v) end)
      |> Enum.reduce(0, fn x, acc -> x + acc end)

    board
    |> Map.replace!(:hp, board.hp - damage)
  end

  defp how_damaged(position, opponent_board = %{state: "attack"}) do
    if dist(position, opponent_board.position) <= opponent_board.attack_area do
      opponent_board.ap
    else
      0
    end
  end

  defp how_damaged(position, opponent_board) do
    if dist(position, opponent_board.position) <= @near do
      opponent_board.ap
    else
      0
    end
  end

  defp replace_dead(board) do
    if board.hp <= 0 do
      Map.replace!(board, :dead?, true)
    else
      board
    end
  end

  defp replace_seen(board, opponent) do
    s =
      opponent
      |> Enum.reject(fn v -> is_nil(v) end)
      |> Enum.reject(fn v -> v.dead? end)
      |> Enum.map(fn v -> whether_seen(board.position, v) end)
      |> Enum.any?()

    board
    |> Map.replace!(:seen?, s)
  end

  defp whether_seen(position, opponent_board = %{state: "search"}) do
    dist(position, opponent_board.position) <= opponent_board.search_area
  end

  defp whether_seen(position, opponent_board) do
    dist(position, opponent_board.position) <= @near
  end

  defp dist({x, y}, {a, b}) do
    abs(x - a) + abs(y - b)
  end

  defp replace_move(board, tick_move) do
    if rem(tick_move, board.speed) == 0 do
      p =
        String.at(board.direction, 0)
        |> move(board.position)

      board
      |> Map.replace!(:position, p)
      |> Map.replace!(:direction, String.slice(board.direction, 1..-1))
    else
      board
    end
  end

  defp move("w", {x, y}) do
    if y < @depth - 1 do
      {x, y + 1}
    else
      {x, y}
    end
  end

  defp move("s", {x, y}) do
    if y > 0 do
      {x, y - 1}
    else
      {x, y}
    end
  end

  defp move("a", {x, y}) do
    if x > 0 do
      {x - 1, y}
    else
      {x, y}
    end
  end

  defp move("d", {x, y}) do
    if x < @width - 1 do
      {x + 1, y}
    else
      {x, y}
    end
  end

  defp move(_, position) do
    position
  end

  defp searcher_white(key) do
    %{
      id: key,
      state: "idle",
      position: {key, 0},
      ap: 1,
      hp: 100,
      attack_area: 1,
      search_area: 4,
      speed: 30,
      seen?: false,
      dead?: false,
      direction: ""
    }
  end

  defp searcher_black(key) do
    %{
      id: key,
      state: "idle",
      position: {key, 7},
      ap: 1,
      hp: 100,
      attack_area: 1,
      search_area: 4,
      speed: 30,
      seen?: false,
      dead?: false,
      direction: ""
    }
  end

  defp attacker_white(key) do
    %{
      id: key,
      state: "idle",
      position: {key, 0},
      ap: 5,
      hp: 400,
      attack_area: 2,
      search_area: 1,
      speed: 60,
      seen?: false,
      dead?: false,
      direction: ""
    }
  end

  defp attacker_black(key) do
    %{
      id: key,
      state: "idle",
      position: {key, 7},
      ap: 5,
      hp: 400,
      attack_area: 2,
      search_area: 1,
      speed: 60,
      seen?: false,
      dead?: false,
      direction: ""
    }
  end
end

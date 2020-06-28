defmodule War.GameMonitor do
  @moduledoc """
  Game processes monitor
  """
  @tick 1000

  use GenServer

  alias War.GameSupervisor

  defstruct finished: false,
            white: [],
            black: []

  def start_monitoring(pid) do
    {:ok, agent} = GenServer.start_link(__MODULE__, pid)
    Process.register(agent, get_pid(pid))
    agent
  end

  def init(pid) do
    schedule_tick(pid)
    {:ok, %__MODULE__{}}
  end

  def get_monitoring(pid) do
    pid
    |> String.to_atom()
    |> GameSupervisor.state()
    |> Map.from_struct()
  end

  def stop_monitoring(pid) do
    GenServer.cast(get_pid(pid), :stop_monitoring)
  end

  def handle_cast(:stop_monitoring, state) do
    {:noreply, Map.replace!(state, :finished, true)}
  end

  def handle_info({:monitor_game, pid}, state) do
    if state.finished do
      {:noreply, state}
    else
      game = GameSupervisor.state(pid)

      black_state =
        case game.board_black do
          [] -> nil
          board -> Enum.map(board, fn v -> {v.position, v.seen?} end)
        end

      white_state =
        case game.board_white do
          [] -> nil
          board -> Enum.map(board, fn v -> {v.position, v.seen?} end)
        end

      schedule_tick(pid)

      if is_nil(white_state) or is_nil(black_state) do
        {:noreply, state}
      else
        {:noreply,
         state
         |> Map.replace!(:white, state.white ++ [white_state])
         |> Map.replace!(:black, state.black ++ [black_state])}
      end
    end
  end

  def get_pid(pid) do
    pid_string = GameSupervisor.state(pid).id
    String.to_atom(pid_string <> "monitor")
  end

  defp schedule_tick(pid) do
    Process.send_after(self(), {:monitor_game, pid}, @tick)
  end
end

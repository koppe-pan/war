defmodule War.GameSupervisor do
  @moduledoc """
  Game processes supervisor
  """
  require Logger
  import DynamicSupervisor, only: [start_child: 2, terminate_child: 2]

  @server_mod War.DynamicGameServerSupervisor
  alias War.{Game}

  @doc """
  Creates a new supervised Game process
  """
  def create_game(id), do: start_child(@server_mod, {Game, [id]})

  def state(pid) do
    :sys.get_state(pid)
  end

  @doc """
  Returns a list of the current games
  """
  def current_games do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(&game_data/1)
  end

  def stop_game(game_id) do
    Logger.debug("Stopping game #{game_id} in supervisor")

    pid = GenServer.whereis({:global, {:game, game_id}})

    Supervisor.terminate_child(__MODULE__, pid)
  end

  defp game_data({_id, pid, _type, _modules}) do
    pid
    |> GenServer.call(:get_data)
    |> Map.take([:id, :attacker, :defender, :turns, :over, :winner])
  end
end

defmodule War.GameSupervisor do
  @moduledoc """
  Game processes supervisor
  """
  require Logger
  import DynamicSupervisor, only: [start_child: 2, terminate_child: 2]

  @server_mod War.DynamicGameServerSupervisor
  alias War.{Game, GameMonitor, Chat}

  @doc """

  Creates a new supervised Game process
  """
  def create_game(id) do
    {:ok, pid} = start_child(@server_mod, {Game, id})
    GameMonitor.start_monitoring(pid)
    Chat.start_chat(pid)
    {:ok, pid}
  end

  def state(pid) do
    :sys.get_state(pid)
  end

  def stop_game(pid, _game = %{white: "finished", black: "finished"}) do
    terminate_child(@server_mod, pid)
  end

  def stop_game(_pid, _game) do
  end
end

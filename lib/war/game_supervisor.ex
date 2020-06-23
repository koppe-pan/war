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
  def create_game(id), do: start_child(@server_mod, {Game, id})

  def state(pid) do
    :sys.get_state(pid)
  end

  def stop_game(pid, _game = %{white: "finished", black: "finished"}) do
    terminate_child(@server_mod, pid)
  end

  def stop_game(_pid, _game) do
  end
end

defmodule War.Game do
  @moduledoc """
  Game server
  """
  use GenServer

  defstruct id: nil,
            board: [
              %{
                id: "1",
                color: "white",
                state: "idle",
                position: {1, 1},
                seen?: false,
                direction: []
              }
            ]

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def init(id) do
    {:ok, %__MODULE__{id: id}}
  end
end

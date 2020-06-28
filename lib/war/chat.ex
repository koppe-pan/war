defmodule War.Chat do
  @moduledoc """
  Game processes monitor
  """
  use GenServer

  alias War.GameSupervisor

  defstruct messages: []

  def start_chat(pid) do
    {:ok, chat_pid} = GenServer.start_link(__MODULE__, pid)
    Process.register(chat_pid, get_pid(pid))
    chat_pid
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def put_message(pid_atom, message, color) do
    GenServer.cast(pid_atom, {:put_message, message, color})
  end

  def get_messages(pid_atom) do
    pid_atom
    |> GameSupervisor.state()
    |> Map.from_struct()
    |> Map.fetch!(:messages)
  end

  def handle_cast({:put_message, message, color}, state) do
    {:noreply, Map.replace!(state, :messages, [{message, color} | state.messages])}
  end

  def get_pid(pid) do
    pid_string = GameSupervisor.state(pid).id
    String.to_atom(pid_string <> "chat")
  end
end

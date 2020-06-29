defmodule WarWeb.ReviewLive do
  use WarWeb, :live_view

  alias War.{GameMonitor, Chat}

  @tick 300

  def mount(_params, %{"review_pid" => pid, "color" => color} = _session, socket) do
    monitor =
      pid
      |> GameMonitor.get_monitoring()

    size = min(Enum.count(monitor.white), Enum.count(monitor.black)) - 1
    chat_atom = get_chat_atom(pid)

    {:ok,
     socket
     |> assign(
       color: color,
       size: size,
       pid: pid,
       play: "",
       chat_atom: chat_atom,
       messages: Chat.get_messages(chat_atom)
     )
     |> update_assigns(0)
     |> schedule_chat_tick()}
  end

  def handle_event(
        "submit-message",
        %{"message" => message},
        socket = %{assigns: %{chat_atom: chat_atom, color: color}}
      ) do
    Chat.put_message(chat_atom, message, color)
    {:noreply, assign(socket, :messages, Chat.get_messages(chat_atom))}
  end

  def handle_event("phase-changed", %{"num" => num}, socket) do
    n = String.to_integer(num)

    {:noreply, update_assigns(socket, n)}
  end

  def handle_event("forward", _, socket) do
    num = min(socket.assigns.number + 1, socket.assigns.size)
    n = find_different_forward_sequence(socket, num)
    {:noreply, update_assigns(socket, n)}
  end

  def handle_event("back", _, socket) do
    num = max(socket.assigns.number - 1, 0)
    n = find_different_back_sequence(socket, num)
    {:noreply, update_assigns(socket, n)}
  end

  def handle_event("play-pause-changed", _, socket = %{assigns: %{play: ""}}) do
    {:noreply,
     socket
     |> assign(play: "checked")
     |> schedule_tick()}
  end

  def handle_event("play-pause-changed", _, socket = %{assigns: %{play: "checked"}}) do
    {:noreply, assign(socket, play: "")}
  end

  def handle_info(:chat_tick, socket) do
    new_socket =
      socket
      |> update_messages()
      |> schedule_chat_tick()

    {:noreply, new_socket}
  end

  def handle_info(:tick, socket) do
    new_socket =
      if socket.assigns.number < socket.assigns.size do
        n = socket.assigns.number + 1

        socket
        |> update_assigns(n)
        |> schedule_tick()
      else
        socket
        |> assign(play: "")
      end

    {:noreply, new_socket}
  end

  defp schedule_chat_tick(socket) do
    Process.send_after(self(), :chat_tick, @tick)
    socket
  end

  defp update_messages(socket) do
    assign(socket, :messages, Chat.get_messages(socket.assigns.chat_atom))
  end

  defp schedule_tick(socket = %{assigns: %{play: "checked"}}) do
    Process.send_after(self(), :tick, @tick)
    socket
  end

  defp schedule_tick(socket = %{assigns: %{play: ""}}) do
    socket
  end

  defp update_assigns(socket, n) do
    socket
    |> assign_pieces(n)
    |> assign_enemies(n)
    |> assign(number: n)
  end

  defp assign_pieces(socket, num) do
    monitor =
      socket.assigns.pid
      |> GameMonitor.get_monitoring()

    p =
      monitor
      |> Map.fetch!(
        socket.assigns.color
        |> String.to_atom()
      )
      |> Enum.fetch!(num)

    assign(socket, pieces: p)
  end

  defp assign_enemies(socket, num) do
    monitor =
      socket.assigns.pid
      |> GameMonitor.get_monitoring()

    e =
      monitor
      |> Map.fetch!(
        socket
        |> opponent_color()
      )
      |> Enum.fetch!(num)

    assign(socket, enemies: e)
  end

  defp get_chat_atom(review_pid) do
    base_pid =
      review_pid
      |> String.slice(0..-8)

    (base_pid <> "chat")
    |> String.to_atom()
  end

  defp find_different_forward_sequence(socket, num) do
    monitor =
      socket.assigns.pid
      |> GameMonitor.get_monitoring()

    p =
      monitor
      |> Map.fetch!(
        socket.assigns.color
        |> String.to_atom()
      )
      |> Enum.fetch!(num)

    e =
      monitor
      |> Map.fetch!(
        socket
        |> opponent_color()
      )
      |> Enum.fetch!(num)

    if p == socket.assigns.pieces and e == socket.assigns.enemies and num < socket.assigns.size do
      find_different_forward_sequence(socket, num + 1)
    else
      num
    end
  end

  defp find_different_back_sequence(socket, num) do
    monitor =
      socket.assigns.pid
      |> GameMonitor.get_monitoring()

    p =
      monitor
      |> Map.fetch!(
        socket.assigns.color
        |> String.to_atom()
      )
      |> Enum.fetch!(num)

    e =
      monitor
      |> Map.fetch!(
        socket
        |> opponent_color()
      )
      |> Enum.fetch!(num)

    if p == socket.assigns.pieces and e == socket.assigns.enemies and num > 0 do
      find_different_back_sequence(socket, num - 1)
    else
      num
    end
  end

  defp opponent_color(%{assigns: %{color: "white"}} = _socket), do: :black
  defp opponent_color(%{assigns: %{color: "black"}} = _socket), do: :white
end

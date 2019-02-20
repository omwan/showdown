defmodule ShowdownWeb.GamesChannel do
  use ShowdownWeb, :channel

  alias Showdown.GameServer

  def join("games:" <> game, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :game, game)
      view = GameServer.join(game, socket.assigns[:username])
      msg = %{"join" => game, "game" => view}
      send(self(), :after_join)
      {:ok, msg, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    broadcast(socket, "join", %{})
    {:noreply, socket}
  end

  def handle_in("move", %{"move" => move}, socket) do
    view = GameServer.move(socket.assigns[:game],
      socket.assigns[:username], move)
    broadcast(socket, "move", %{submitted_moves: view.submitted_moves})
    {:noreply, socket}
  end

  def handle_in("view", _params, socket) do
    view = GameServer.view(socket.assigns[:game], socket.assigns[:username])
    {:reply, {:ok, %{"game" => view}}, socket}
  end

  def handle_in("apply", _params, socket) do
    view = GameServer.apply(socket.assigns[:game], socket.assigns[:username])
    {:reply, {:ok, %{"game" => view}}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

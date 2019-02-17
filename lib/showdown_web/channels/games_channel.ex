defmodule ShowdownWeb.GamesChannel do
  use ShowdownWeb, :channel

  alias Showdown.GameServer

  def join("games:" <> game, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :game, game)
      view = GameServer.view(game, socket.assigns[:username])
      {:ok, %{"join" => game, "game" => view}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("move", %{"move" => move}, socket) do
    view = GameServer.move(socket.assigns[:game],
      socket.assigns[:username], move)
    {:reply, {:ok, %{"game" => view}}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

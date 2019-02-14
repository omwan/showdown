defmodule ShowdownWeb.GamesChannel do
  use ShowdownWeb, :channel

  alias Showdown.Game
  alias Showdown.BackupAgent

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      game = BackupAgent.get(name) || Game.new()
      BackupAgent.put(name, game)
      socket = socket
               |> assign(:game, game)
               |> assign(:name, name)
      {:ok, %{"join" => name, "game" => Game.client_view(game)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("roll", payload, socket) do
    resp = %{"roll" => :rand.uniform(6)}
    {:reply, {:roll, resp}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

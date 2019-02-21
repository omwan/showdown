defmodule ShowdownWeb.GamesChannel do
  use ShowdownWeb, :channel

  alias Showdown.GameServer

  @doc """
  Add a new user to the game.
  """
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

  @doc """
  Broadcast that a new user has joined the game.
  """
  def handle_info(:after_join, socket) do
    broadcast(socket, "join", %{})
    {:noreply, socket}
  end

  @doc """
  Accept a user's move and broadcast that a move has been submitted.
  """
  def handle_in("move", %{"move" => move}, socket) do
    view = GameServer.move(socket.assigns[:game],
      socket.assigns[:username], move)
    broadcast(socket, "move", %{submitted_moves: view.submitted_moves})
    {:noreply, socket}
  end

  @doc """
  Get the client view for this user of the current game state.
  """
  def handle_in("view", _params, socket) do
    view = GameServer.view(socket.assigns[:game], socket.assigns[:username])
    {:reply, {:ok, %{"game" => view}}, socket}
  end

  @doc """
  Apply the effects of the moves submitted and get the updated client view.
  """
  def handle_in("apply", _params, socket) do
    view = GameServer.apply(socket.assigns[:game], socket.assigns[:username])
    {:reply, {:ok, %{"game" => view}}, socket}
  end

  @doc """
  End the game.
  """
  def handle_in("end", _params, socket) do
    view = GameServer.end_game(socket.assigns[:game], socket.assigns[:username])
    {:reply, {:ok, %{}}, socket}
  end

  defp authorized?(_payload) do
    true
  end
end

defmodule Showdown.GameServer do
  use GenServer

  alias Showdown.Game

  ## Client Interface
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def view(game, username) do
    GenServer.call(__MODULE__, {:view, game, username})
  end

  def move(game, username, move) do
    GenServer.call(__MODULE__, {:guess, game, username, move})
  end

  ## Implementations
  def init(state) do
    {:ok, state}
  end

  def handle_call({:view, game, username}, _from, state) do
    gg = Map.get(state, game, Game.new)
    {:reply, Game.client_view(gg, username), Map.put(state, game, gg)}
  end

  def handle_call({:move, game, username, move}, _from, state) do
    gg = Map.get(state, game, Game.new)
         |> Game.move(username, move)
    vv = Game.client_view(gg, username)
    {:reply, vv, Map.put(state, game, gg)}
  end
end
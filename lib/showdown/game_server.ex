defmodule Showdown.GameServer do
  use GenServer

  alias Showdown.Game

  ## Client Interface
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def join(game, username) do
    GenServer.call(__MODULE__, {:join, game, username})
  end

  def view(game, username) do
    GenServer.call(__MODULE__, {:view, game, username})
  end

  def move(game, username, move) do
    GenServer.call(__MODULE__, {:move, game, username, move})
  end

  def apply(game, username) do
    GenServer.call(__MODULE__, {:view, game, username})
  end

  ## Implementations
  def init(state) do
    {:ok, state}
  end

  def handle_call({:join, game, username}, _from, state) do
    new_game = Map.get(state, game, Game.new)
               |> Game.join(username)
    {:reply, Game.client_view(new_game, username), Map.put(state, game, new_game)}
  end

  def handle_call({:view, game, username}, _from, state) do
    new_game = Map.get(state, game, Game.new)
    {:reply, Game.client_view(new_game, username), Map.put(state, game, new_game)}
  end

  def handle_call({:move, game, username, move}, _from, state) do
    new_game = Map.get(state, game, Game.new)
               |> Game.move(username, move)
    view = Game.client_view(new_game, username)
    {:reply, view, Map.put(state, game, new_game)}
  end

  def handle_call({:apply, game, username}, _from, state) do
    new_game = Map.get(state, game, Game.new)
               |> Game.apply(username)
    view = Game.client_view(new_game, username)
    {:reply, view, Map.put(state, game, new_game)}
  end
end
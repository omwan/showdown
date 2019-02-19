defmodule Showdown.GameServer do
  use GenServer

  alias Showdown.Game

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker,
    }
    Showdown.GameSup.start_child(spec)
  end

  ## Client Interface
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def join(name, username) do
    GenServer.call(__MODULE__, {:join, name, username})
  end

  def view(name, username) do
    GenServer.call(__MODULE__, {:view, name, username})
  end

  def move(name, username, move) do
    GenServer.call(__MODULE__, {:move, name, username, move})
  end

  def apply(name, username) do
    GenServer.call(__MODULE__, {:view, name, username})
  end

  ## Implementations
  def init(state) do
    {:ok, state}
  end

  def handle_call({:join, name, username}, _from, state) do
    game = Map.get(state, name, Game.new)
           |> Game.join(username)
    {:reply, Game.client_view(game, username), Map.put(state, name, game)}
  end

  def handle_call({:view, name, username}, _from, state) do
    game = Map.get(state, name, Game.new)
    {:reply, Game.client_view(game, username), Map.put(state, name, game)}
  end

  def handle_call({:move, name, username, move}, _from, state) do
    game = Map.get(state, name, Game.new)
           |> Game.move(username, move)
    view = Game.client_view(game, username)
    {:reply, view, Map.put(state, name, game)}
  end

  def handle_call({:apply, name, username}, _from, state) do
    game = Map.get(state, name, Game.new)
           |> Game.apply(username)
    view = Game.client_view(game, username)
    {:reply, view, Map.put(state, name, game)}
  end
end
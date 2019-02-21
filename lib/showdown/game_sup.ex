defmodule Showdown.GameSup do
  use DynamicSupervisor

  # Referenced from https://github.com/NatTuck/hangman-2019-01/compare/02-04-backup-agent...02-06-multiplayer#diff-4fc94f672f949ec0891d59252e2781f6

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    {:ok, _} = Registry.start_link(keys: :unique, name: Showdown.GameReg)
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

end
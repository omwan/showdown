defmodule Showdown.Game do

  def new do
    %{
      key: "value"
    }
  end

  def client_view(game, user) do
    game
  end

  def move(game, _user, _move) do
    game
  end

end

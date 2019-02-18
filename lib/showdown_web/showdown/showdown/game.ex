defmodule Showdown.Game do

  alias Showdown.Pokemon

  def new do
    %{
      players: %{}
    }
  end

  def new_player(name) do
    %User{
      name: name,
      team: [get_pokemon()]
    }
  end

  def join(game, player) do
    players = Map.put(game.players, player, new_player(player))
    Map.put(game, :players, players)
  end

  def opponent_team_view(game, opponent_name) do
    opponent = game.players[opponent_name]
    Enum.map(opponent.team, fn pokemon ->
      %{
        name: pokemon.name,
        hp: pokemon.hp
      }
    end)
  end

  def client_view(game, user) do
    players = Map.keys(game.players)
    filtered_names = Enum.filter(players, fn player ->
      player != user
    end)

    if length(filtered_names) == 1 do
      [opponent] = filtered_names
      %{
        player: game.players[user],
        opponent: %{
          name: opponent,
          team: opponent_team_view(game, opponent)
        }
      }
    else
      %{
        player: game.players[user],
      }
    end
  end


  def move(game, _user, _move) do
    game
  end

  def get_pokemon do
    pokemon = [
      %Pokemon{
        name: "bulbasaur",
        speed: 2,
        attack: 2,
        defense: 2,
        hp: 10,
        type: "grass",
        moves: [
          %Move{
            name: "vine whip",
            type: "grass",
            power: 2
          },
          %Move{
            name: "tackle",
            type: "normal",
            power: 2
          }
        ]
      },
      %Pokemon{
        name: "charmander",
        speed: 1,
        attack: 1,
        defense: 3,
        hp: 8,
        type: "",
        moves: [
          %Move{
            name: "ember",
            type: "fire",
            power: 2
          },
          %Move{
            name: "scratch",
            type: "normal",
            power: 2
          }
        ]
      },
      %Pokemon{
        name: "squirtle",
        speed: 3,
        attack: 3,
        defense: 1,
        hp: 12,
        moves: [
          %Move{
            name: "water gun",
            type: "water",
            power: 2
          },
          %Move{
            name: "tackle",
            type: "normal",
            power: 2
          }
        ]
      }
    ]

    Enum.random(pokemon)
  end

end

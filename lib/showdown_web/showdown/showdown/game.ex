defmodule Showdown.Game do

  alias Showdown.Pokemon

  def new do
    %{
      players: %{},
    }
  end

  def new_player(username) do
    team = [get_pokemon()]
    %Player{
      name: username,
      team: team,
      current_pokemon: Enum.at(team, 0)
    }
  end

  def join(game, username) do
    if map_size(game.players) < 2 do
      players = Map.put(game.players, username, new_player(username))
      Map.put(game, :players, players)
    else
      game
    end
  end

  def opp_pokemon_view(game, pokemon) do
    %{
      name: pokemon.name,
      hp: pokemon.hp
    }
  end

  def opp_team_view(game, opponent) do
    Enum.map(opponent.team, fn pokemon ->
      %{
        name: pokemon.name
      }
    end)
  end

  def client_view(game, username) do
    players = Map.keys(game.players)
    filtered_names = Enum.filter(players, fn player ->
      player != username
    end)

    if length(filtered_names) == 1 do
      [opponent_name] = filtered_names
      opponent = game.players[opponent_name]
      %{
        player: game.players[username],
        opponent: %{
          name: opponent_name,
          current_pokemon: opp_pokemon_view(game, opponent.current_pokemon),
          team: opp_team_view(game, opponent)
        }
      }
    else
      %{
        player: game.players[username],
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

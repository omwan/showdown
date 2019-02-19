defmodule Showdown.Game do

  alias Showdown.Pokemon

  def new do
    %{
      players: %{},
      sequence: [],
      submitted_moves: %{}
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
      if not Map.has_key?(game.players, username) do
        players = Map.put(game.players, username, new_player(username))
        Map.put(game, :players, players)
      else
        game
      end
    else
      game
    end
  end

  def opp_pokemon_view(pokemon) do
    %{
      name: pokemon.name,
      hp: pokemon.hp,
      max_hp: pokemon.max_hp
    }
  end

  def opp_team_view(opponent) do
    Enum.map(opponent.team, fn pokemon ->
      %{
        name: pokemon.name
      }
    end)
  end

  def get_opponent(game, current_user) do
    players = Map.keys(game.players)
    filtered_names = Enum.filter(players, fn player ->
      player != current_user
    end)
    if length(filtered_names) == 1 do
      [opponent_name] = filtered_names
      game.players[opponent_name]
    else
      nil
    end
  end

  def client_view(game, username) do
    opponent = get_opponent(game, username)
    if opponent == nil do
      %{
        player: game.players[username]
      }
    else
      %{
        player: game.players[username],
        opponent: %{
          name: opponent.name,
          current_pokemon: opp_pokemon_view(opponent.current_pokemon),
          team: opp_team_view(opponent)
        },
        submitted_moves: Enum.map(game.submitted_moves, fn {name, _move} ->
          name
        end),
        sequence: game.sequence
      }
    end
  end

  def calculate_hp(game, username, move) do
    opponent = get_opponent(game, username)
    opp_pokemon = opponent.current_pokemon
    opp_hp = opp_pokemon.hp

    player = game.players[username]
    player_pokemon = player.current_pokemon
    [player_move] = Enum.filter(player_pokemon.moves, fn m ->
      m.name == move
    end)
    damage = trunc((player_pokemon.attack / opp_pokemon.defense) * player_move.power)
    max(0, opp_hp - damage)
  end

  def build_sequence(game) do
    moves = game.submitted_moves
    sequence = Map.to_list(moves)
      |> Enum.sort_by(fn {username, _move} ->
        player = game.players[username]
        current_pokemon = player.current_pokemon
        current_pokemon.speed
      end)
      |> Enum.map(fn {username, move} ->
        attacker = game.players[username]
        att_pokemon = attacker.current_pokemon

        opponent = get_opponent(game, username)
        opp_pokemon = opponent.current_pokemon
        %{
          player: username,
          opponent: opponent.name,
          attacker: att_pokemon.name,
          recipient: opp_pokemon.name,
          move: move,
          opponent_remaining_hp: calculate_hp(game, username, move)
        }
      end)
    Map.put(game, :sequence, sequence)
  end

  def move(game, username, move) do
    if not Map.has_key?(game.submitted_moves, username) do
      submitted_moves = Map.put(game.submitted_moves, username, move)
      if map_size(submitted_moves) == 2 do
        build_sequence(Map.put(game, :submitted_moves, submitted_moves))
      else
        Map.put(game, :submitted_moves, submitted_moves)
      end
    else
      game
    end
  end

  def apply(game, _username) do
    if length(game.sequence) == 2 do
      updates = game.sequence
        |> Enum.map(fn item ->
             {item.opponent, item.opponent_remaining_hp}
           end)
        |> Map.new

      players = Enum.map(game.players, fn {name, player} ->
        update = updates[name]
        pokemon = Map.put(player.current_pokemon, :hp, update)
        team = Enum.map(player.team, fn pkmn ->
          if pkmn.name == pokemon.name do
            Map.put(pkmn, :hp, update)
          end
        end)
        {name, Map.put(Map.put(player, :team, team), :current_pokemon, pokemon)}
      end)
        |> Map.new
      %{game | players: players, sequence: [], submitted_moves: %{}}
    else
      game
    end
  end

  def get_pokemon do
    pokemon = [
      %Pokemon{
        name: "bulbasaur",
        speed: 2,
        attack: 2,
        defense: 2,
        hp: 30,
        max_hp: 30,
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
        speed: 3,
        attack: 3,
        defense: 1,
        hp: 24,
        max_hp: 24,
        type: "fire",
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
        speed: 1,
        attack: 1,
        defense: 3,
        hp: 36,
        max_hp: 36,
        type: "water",
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

defmodule Showdown.Game do

  alias Showdown.Pokemon

  @doc """
  Build a new game object without players.
  """
  def new do
    %{
      players: %{},
      sequence: [],
      submitted_moves: %{},
      winner: ""
    }
  end

  @doc """
  Build a new player with a team consisting of a single randomly selected pokemon,
  and setting the current pokemon to the first pokemon in the team.
  """
  def new_player(username) do
    team = [get_pokemon()]
    %Player{
      name: username,
      team: team,
      current_pokemon: Enum.at(team, 0)
    }
  end

  @doc """
  Add a player to the game. Limit to two players per game, no spectators.
  """
  def join(game, username) do
    if map_size(game.players) < 2 do
      players = Map.put_new(game.players, username, new_player(username))
      Map.put(game, :players, players)
    else
      game
    end
  end

  @doc """
  Build client view of opposing pokemon, hiding their moves and stats.
  """
  def opp_pokemon_view(pokemon) do
    %{
      name: pokemon.name,
      hp: pokemon.hp,
      max_hp: pokemon.max_hp
    }
  end

  @doc """
  Build client view of opposing player's team, hiding everything except their name.
  """
  def opp_team_view(opponent) do
    Enum.map(opponent.team, fn pokemon ->
      %{
        name: pokemon.name
      }
    end)
  end

  @doc """
  Identify current player's opponent from player map of game.
  """
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

  @doc """
  Identify whether the current user has won or lost, or if the game is still ongoing.
  """
  def get_win_lose(game, username) do
    cond do
      game.winner == "" ->
        ""
      game.winner == username ->
        "won"
      true ->
       "lost"
    end
  end

  @doc """
  Build the client view of the game, hiding information about the opponent's pokemon
  and team and categorizing data as being associated to this player or the opponent.
  """
  def client_view(game, username) do
    opponent = get_opponent(game, username)
    if opponent == nil do
      %{
        player: game.players[username]
      }
    else
      view = %{
        player: game.players[username],
        opponent: %{
          name: opponent.name,
          current_pokemon: opp_pokemon_view(opponent.current_pokemon),
          team: opp_team_view(opponent)
        },
        submitted_moves: map_size(game.submitted_moves),
        player_move: game.submitted_moves[username],
        sequence: game.sequence,
      }
      if length(game.sequence) == 0 do
        Map.put(view, :finished, get_win_lose(game, username))
      else
        view
      end
    end
  end

  @doc """
  Get type effectiveness modifier based off the type of the move and the type
  of the pokemon the move is being executed on.
  Type effectiveness sequence is water -> fire -> grass -> water.
  """
  def type_effectiveness(opp_type, move_type) do
   
    case opp_type do
      "fire" ->
        case move_type do
          type when type in ["water", "rock", "ground"] ->
            2.0
          type when type in ["grass", "fire", "bug", "steel", "ice"] ->
            0.5
          _ ->
            1
        end
      "water" ->
        case move_type do
          type when type in ["grass", "electric"] ->
            2.0
            type when type in ["fire", "water", "steel", "ice"] ->
            0.5
          _ ->
            1
        end
      "grass" ->
        case move_type do
          type when type in ["fire", "flying", "poison", "bug", "ice"] ->
            2.0
            type when type in ["water", "grass"] ->
            0.5
          _ ->
            1
        end
        "normal" ->
          case move_type do
            "fighting" ->
              2.0
            "ghost" ->
              0
            _ ->
              1
          end
    end
  end

  @doc """
  Get Same-Type Attack Bonus modifier--1.5 if the move selected is of the same type
  as the pokemon executing it.
  """
  def stab(pokemon_type, move_type) do
    if pokemon_type == move_type do
      1.5
    else
      1
    end
  end

  @doc """
  Calculate total modifier (type effectiveness * STAB).
  """
  def calculate_modifier(opp_type, move_type, pokemon_type) do
    stab = stab(pokemon_type, move_type)
    te = type_effectiveness(opp_type, move_type)
    stab * te
  end

  @doc """
  Calculate total damage done to the opposing pokemon based on the attacking pokemon's
  stats, move power, and opposing pokemon's stats.
  """
  def calculate_damage(player_pokemon, player_move, opp_pokemon) do
    modifier = calculate_modifier(opp_pokemon.type, player_move.type, player_pokemon.type)
    base_damage = ((player_pokemon.attack / opp_pokemon.defense) * player_move.power) * (Enum.random(85..100) / 100)
    trunc((base_damage / 10) * modifier)
  end

  @doc """
  Calculate the resulting HP of the pokemon after a move has been executed on it, or 0
  if the damage done is greater than the remaining HP.
  """
  def calculate_hp(game, username, move) do
    opponent = get_opponent(game, username)
    opp_pokemon = opponent.current_pokemon
    opp_hp = opp_pokemon.hp

    player = game.players[username]
    player_pokemon = player.current_pokemon
    [player_move] = Enum.filter(player_pokemon.moves, fn m ->
      m.name == move
    end)

    damage = calculate_damage(player_pokemon, player_move, opp_pokemon)
    max(0, opp_hp - damage)
  end

  @doc """
  Based on the submitted moves, build the sequence that the moves will be executed in, and
  the HP of the attacked pokemon after the move is executed. The pokemon with the higher
  speed stat will move first.
  """
  def build_sequence(game) do
    moves = game.submitted_moves
    sequence = Map.to_list(moves)
      |> Enum.sort_by(fn {username, _move} ->
        player = game.players[username]
        current_pokemon = player.current_pokemon
        current_pokemon.speed
      end)
      |> Enum.reverse
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
    sequence
  end

  @doc """
  If at least one pokemon's HP drops to 0 in the sequence of moves, the game has ended.
  """
  def has_ended?(sequence) do
    fainted_pokemon = Enum.filter(sequence, fn event ->
      event.opponent_remaining_hp == 0
    end)
    length(fainted_pokemon) > 0
  end

  @doc """
  Once the game has ended, identify the winner. The winner is the player who knocks
  out the opposing player's pokemon first in the sequence of moves.
  """
  def get_winner(sequence) do
    cond do
      sequence == [] ->
        nil
      hd(sequence).opponent_remaining_hp == 0 ->
        hd(sequence)
      true ->
        get_winner(tl(sequence))
    end
  end

  @doc """
  To end a game, identify the winner and update the game with it, and truncate the sequence
  if the first move executed knocks out the other pokemon.
  """
  def end_game(game, sequence) do
    winner = get_winner(sequence)
    game = Map.put(game, :winner, winner.player)
    if Enum.at(sequence, 0) == winner do
      Map.put(game, :sequence, [hd(sequence)])
    else
      Map.put(game, :sequence, sequence)
    end
  end

  @doc """
  User submits a move to the game, and it is added to the map of submitted moves with the key
  being the username of that user. Once inputted, the move cannot be changed.
  """
  def move(game, username, move) do
    if not Map.has_key?(game.submitted_moves, username) do
      submitted_moves = Map.put(game.submitted_moves, username, move)
      if map_size(submitted_moves) == 2 do
        sequence = build_sequence(Map.put(game, :submitted_moves, submitted_moves))
        if has_ended?(sequence) do
          end_game(Map.put(game, :submitted_moves, submitted_moves), sequence)
        else
          %{game | submitted_moves: submitted_moves, sequence: sequence}
        end
      else
        Map.put(game, :submitted_moves, submitted_moves)
      end
    else
      game
    end
  end

  @doc """
  After the animation of the sequence is complete in the front end, this function is called
  to update the HP of all pokemon with the values in the sequence, and the sequence and
  submitted moves fields of the game are reset to empty.
  """
  def apply(game, _username) do
    if length(game.sequence) > 0 do
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

  @doc"""
  Retrieves a random pokemon from the list of available pokemon.
  """
  def get_pokemon do
    pokemon = [
      %Pokemon{
        name: "bulbasaur",
        speed: 45,
        attack: 49,
        defense: 49,
        hp: 45,
        max_hp: 45,
        type: "grass",
        moves: [
          %Move{
            name: "vine whip",
            type: "grass",
            power: 45
          },
          %Move{
            name: "tackle",
            type: "normal",
            power: 40
          },
          %Move{
            name: "watering can",
            type: "water",
            power: 30
          },
          %Move{
            name: "sludge bomb",
            type: "poison",
            power: 60
          }
        ]
      },
      %Pokemon{
        name: "charmander",
        speed: 65,
        attack: 52,
        defense: 43,
        hp: 39,
        max_hp: 39,
        type: "fire",
        moves: [
          %Move{
            name: "ember",
            type: "fire",
            power: 40
          },
          %Move{
            name: "scratch",
            type: "normal",
            power: 40
          },
          %Move{
            name: "tazer",
            type: "electric",
            power: 30
          },
          %Move{
            name: "metal claw",
            type: "steel",
            power: 60
          }
        ]
      },
      %Pokemon{
        name: "squirtle",
        speed: 43,
        attack: 48,
        defense: 65,
        hp: 44,
        max_hp: 44,
        type: "water",
        moves: [
          %Move{
            name: "water gun",
            type: "water",
            power: 40
          },
          %Move{
            name: "tackle",
            type: "normal",
            power: 40
          },
          %Move{
            name: "regular gun",
            type: "steel",
            power: 60
          },
          %Move{
            name: "karate",
            type: "fighting",
            power: 30
          }
        ]
      },
      %Pokemon{
        name: "eevee",
        speed: 55,
        attack: 55,
        defense: 50,
        hp: 55,
        max_hp: 55,
        type: "normal",
        moves: [
          %Move{
            name: "tackle",
            type: "normal",
            power: 40
          },
          %Move{
            name: "bite",
            type: "dark",
            power: 60
          },
          %Move{
            name: "swag",
            type: "Nice",
            power: 69
          },
          %Move{
            name: "shadow ball",
            type: "ghost",
            power: 60
          }
        ]
      }
    ]

    Enum.random(pokemon)
  end

end

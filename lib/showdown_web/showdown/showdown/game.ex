defmodule Showdown.Game do

  alias Showdown.Pokemon

  def new do
    %{
      players: %{},
      sequence: [],
      submitted_moves: %{},
      winner: ""
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
      players = Map.put_new(game.players, username, new_player(username))
      Map.put(game, :players, players)
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
        submitted_moves: map_size(game.submitted_moves),
        player_move: game.submitted_moves[username],
        sequence: game.sequence,
        finished: get_win_lose(game, username),
      }
    end
  end

  def type_effectiveness(opp_type, move_type) do
    case opp_type do
      "fire" ->
        case move_type do
          "water" ->
            2.0
          "grass" ->
            0.5
          _ ->
            1
        end
      "water" ->
        case move_type do
          "grass" ->
            2.0
          "fire" ->
            0.5
          _ ->
            1
        end
      "grass" ->
        case move_type do
          "fire" ->
            2.0
          "water" ->
            0.5
          _ ->
            1
        end
    end
  end

  def stab(pokemon_type, move_type) do
    if pokemon_type == move_type do
      1.5
    else
      1
    end
  end

  def calculate_modifier(opp_type, move_type, pokemon_type) do
    stab = stab(pokemon_type, move_type)
    te = type_effectiveness(opp_type, move_type)
    stab * te
  end

  def calculate_damage(player_pokemon, player_move, opp_pokemon) do
    modifier = calculate_modifier(opp_pokemon.type, player_move.type, player_pokemon.type)
    base_damage = ((player_pokemon.attack / opp_pokemon.defense) * player_move.power)
    trunc((base_damage / 10) * modifier)
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

    damage = calculate_damage(player_pokemon, player_move, opp_pokemon)
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

  def has_ended?(sequence) do
    fainted_pokemon = Enum.filter(sequence, fn event ->
      event.opponent_remaining_hp == 0
    end)
    length(fainted_pokemon) > 0
  end

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

  def end_game(game, username, sequence) do
    winner = get_winner(sequence)
    game = Map.put(game, :winner, winner.player)
    if Enum.at(sequence, 0) == winner do
      Map.put(game, :sequence, [hd(sequence)])
    else
      Map.put(game, :sequence, sequence)
    end
  end

  def move(game, username, move) do
    if not Map.has_key?(game.submitted_moves, username) do
      submitted_moves = Map.put(game.submitted_moves, username, move)
      if map_size(submitted_moves) == 2 do
        sequence = build_sequence(Map.put(game, :submitted_moves, submitted_moves))
        if has_ended?(sequence) do
          end_game(game, username, sequence)
        else
          Map.put(game, :sequence, sequence)
        end
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
        speed: 45,
        attack: 49,
        defense: 49,
        hp: 15,
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
          }
        ]
      },
      %Pokemon{
        name: "charmander",
        speed: 65,
        attack: 52,
        defense: 43,
        hp: 15,
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
          }
        ]
      },
      %Pokemon{
        name: "squirtle",
        speed: 43,
        attack: 48,
        defense: 65,
        hp: 15,
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
          }
        ]
      }
    ]

    Enum.random(pokemon)
  end

end

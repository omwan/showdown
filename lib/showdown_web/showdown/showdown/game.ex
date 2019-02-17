defmodule Showdown.Game do

  alias Showdown.Pokemon

  def new do
    %{
      users: [
        %User{
          name: "user 1",
          team: [get_pokemon()]
        },
        %User{
          name: "user 2",
          team: [get_pokemon()]
        }
      ],
      submitted_moves: [
      ]
    }
  end

  def client_view(game, user) do
    game
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

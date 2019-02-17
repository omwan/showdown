defmodule ShowdownWeb.PageController do
  use ShowdownWeb, :controller

  def index(conn, _params) do
    username = get_session(conn, :username)
    render conn, "index.html", username: username
  end

  def game(conn, %{"game" => game}) do
    username = get_session(conn, :username)
    if username do
      render conn, "game.html", game: game, username: username
    else
      conn
      |> put_flash(:error, "Must pick a username")
      |> redirect(to: "/")
    end
  end
end

defmodule ShowdownWeb.SessionController do
  use ShowdownWeb, :controller

  def create(conn, %{"username" => username}) do
    conn
    |> put_session(:username, username)
    |> put_flash(:info, "Logged in as " <> username)
    |> redirect(to: "/")
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:username)
    |> put_flash(:info, "Successfully logged out")
    |> redirect(to: "/")
  end

end

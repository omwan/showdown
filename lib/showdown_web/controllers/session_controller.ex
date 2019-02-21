defmodule ShowdownWeb.SessionController do
  use ShowdownWeb, :controller

  # Referenced from https://github.com/NatTuck/husky_shop/compare/2-deploy...3-users#diff-501b6001d573b9bc1ffba704a1bdc907

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

defmodule ShowdownWeb.Plugs.FetchSession do
  import Plug.Conn

  # Referenced from https://github.com/NatTuck/husky_shop/compare/2-deploy...3-users#diff-2c6d7e4b7b6ebe78b01a8847ad5ac5bc

  def init(_args) do
    :args
  end

  def call(conn, _args) do
    if username = get_session(conn, :username) do
      token = Phoenix.Token.sign(conn, "user socket", username)
      assign(conn, :user_token, token)
    else
      assign(conn, :user_token, "")
    end
  end
end

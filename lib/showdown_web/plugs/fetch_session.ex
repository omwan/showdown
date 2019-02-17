defmodule ShowdownWeb.Plugs.FetchSession do
  import Plug.Conn

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

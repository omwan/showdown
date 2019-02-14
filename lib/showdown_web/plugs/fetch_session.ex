defmodule ShowdownWeb.Plugs.FetchSession do
  import Plug.Conn

  def init(_args) do
    :args
  end

  def call(conn, _args) do
    username = get_session(conn, :username)
    assign(conn, :username, username)
  end
end

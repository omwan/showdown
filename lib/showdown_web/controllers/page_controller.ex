defmodule ShowdownWeb.PageController do
  use ShowdownWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end

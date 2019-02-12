defmodule ShowdownWeb.GamesChannel do
  use ShowdownWeb, :channel

  def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
      {:ok, %{"join" => name}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("roll", payload, socket) do
    resp = %{ "roll" => :rand.uniform(6) }
    {:reply, {:roll, resp}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

defmodule GrapevineSocket.GameView do
  alias GrapevineData.UserAgents

  def render("status.json", %{game: game}) do
    json = %{game: game.short_name, display_name: game.name}

    json
    |> maybe_add(:description, game.description)
    |> maybe_add(:homepage_url, game.homepage_url)
    |> maybe_add(:user_agent, game.user_agent)
    |> maybe_add(:user_agent_url, user_agent_repo_url(game.user_agent))
    |> maybe_add_connections(game)
  end

  def render("connection.json", %{connection: connection}) do
    case connection.type do
      "telnet" ->
        Map.take(connection, [:type, :host, :port])

      "secure telnet" ->
        Map.take(connection, [:type, :host, :port])

      "web" ->
        Map.take(connection, [:type, :url])
    end
  end

  defp maybe_add_connections(json, game) do
    case game.connections do
      [] ->
        json

      connections ->
        Map.put(json, :connections, format_connections(connections))
    end
  end

  defp format_connections(connections) do
    Enum.map(connections, fn connection ->
      render("connection.json", %{connection: connection})
    end)
  end

  defp user_agent_repo_url(nil), do: nil

  defp user_agent_repo_url(user_agent) do
    with {:ok, user_agent} <- UserAgents.get_user_agent(user_agent),
         {:ok, user_agent} <- check_if_repo_url(user_agent) do
      user_agent.repo_url
    else
      _ ->
        nil
    end
  end

  defp maybe_add(json, _field, nil), do: json

  defp maybe_add(json, field, value) do
    Map.put(json, field, value)
  end

  defp check_if_repo_url(user_agent) do
    case user_agent.repo_url do
      nil ->
        {:error, :no_repo_url, user_agent}

      _ ->
        {:ok, user_agent}
    end
  end
end

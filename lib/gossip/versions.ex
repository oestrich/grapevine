defmodule Gossip.Versions do
  @moduledoc """
  Context around tracking schema versions for sync
  """

  import Ecto.Query

  alias Gossip.Channels.Channel
  alias Gossip.Events.Event
  alias Gossip.Games.Game
  alias Gossip.Repo
  alias Gossip.UserAgents
  alias Gossip.Versions.Version
  alias Web.ConnectionView

  @doc """
  Log a new action on a supported schema

  Actions can be one of: create, update, delete
  """
  def log(action, schema, logged_at \\ Timex.now()) do
    attributes = %{
      action: action,
      schema: schema_for(schema),
      schema_id: schema.id,
      payload: payload_for(schema),
      logged_at: logged_at,
    }

    %Version{}
    |> Version.changeset(attributes)
    |> Repo.insert()
  end

  def for(schema, nil) do
    Version
    |> where([v], v.schema == ^schema)
    |> Repo.all()
  end

  def for(schema, since) do
    Version
    |> where([v], v.schema == ^schema)
    |> where([v], v.logged_at >= ^since)
    |> Repo.all()
  end

  defp schema_for(%Channel{}), do: "channels"
  defp schema_for(%Event{}), do: "events"
  defp schema_for(%Game{}), do: "games"

  defp payload_for(channel = %Channel{}) do
    Map.take(channel, Channel.__schema__(:fields))
  end

  defp payload_for(event = %Event{}) do
    Map.take(event, Event.__schema__(:fields))
  end

  defp payload_for(game = %Game{}) do
    %{
      id: game.id,
      game: game.short_name,
      display_name: game.name,
      display: game.display,
      description: game.description,
      homepage_url: game.homepage_url,
      user_agent: game.user_agent,
      user_agent_url: user_agent_repo_url(game.user_agent),
      connections: format_connections(game.connections),
      redirect_uris: format_redirect_uris(game.redirect_uris),
      allow_character_registration: game.allow_character_registration,
      client_id: game.client_id,
      client_secret: game.client_secret,
    }
  end

  defp format_connections(connections) do
    connections
    |> Enum.map(fn connection ->
      ConnectionView.render("show.json", %{connection: connection})
    end)
  end

  defp format_redirect_uris(redirect_uris) do
    Enum.map(redirect_uris, &(&1.uri))
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

  defp check_if_repo_url(user_agent) do
    case user_agent.repo_url do
      nil ->
        {:error, :no_repo_url, user_agent}

      _ ->
        {:ok, user_agent}
    end
  end
end

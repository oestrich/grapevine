defmodule Web.GameView do
  use Web, :view

  alias Gossip.Channels
  alias Gossip.Presence
  alias Gossip.UserAgents

  def render("online.json", %{games: games}) do
    %{
      collection: render_many(games, __MODULE__, "presence.json")
    }
  end

  def render("presence.json", %{game: game}) do
    %{
      game: Map.take(game.game, [:name, :homepage_url]),
      players: game.players
    }
  end

  def user_agent(game) do
    case game.user_agent do
      nil ->
        nil

      user_agent ->
        display_user_agent(user_agent)
    end
  end

  defp display_user_agent(user_agent) do
    with {:ok, user_agent} <- UserAgents.get_user_agent(user_agent),
         {:ok, user_agent} <- check_if_repo_url(user_agent) do
      link(user_agent.version, to: user_agent.repo_url, target: "_blank")
    else
      {:error, :no_repo_url, user_agent} ->
        user_agent.version

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

  def display_channel?(channel) do
    case Channels.get(channel) do
      {:ok, channel} ->
        !channel.hidden

      _ ->
        false
    end
  end

  def online_players(game) do
    presence =
      Enum.find(Presence.online_games(), fn presence ->
        presence.game.id == game.id
      end)

    case presence do
      nil ->
        []

      presence ->
        presence.players
    end
  end

  def online_status(game) do
    active_cutoff = Timex.now() |> Timex.shift(minutes: -1)

    case Timex.before?(active_cutoff, game.last_seen_at) do
      true ->
        content_tag(:i, "", class: "fa fa-circle online", alt: "Game Online", title: "Online")

      _ ->
        mssp_cutoff = Timex.now() |> Timex.shift(minutes: -90)

        case Timex.before?(mssp_cutoff, game.mssp_last_seen_at) do
          true ->
            content_tag(:i, "", class: "fa fa-adjust online", alt: "Seen on MSSP", title: "Seen on MSSP")

          _ ->
            content_tag(:i, "", class: "fa fa-circle offline", alt: "Game Offline", title: "Offline")
        end
    end
  end

  def connection_info(connection) do
    case connection.type do
      "web" ->
        link(connection.url, to: connection.url, target: "_blank")

      "telnet" ->
        "#{connection.host}:#{connection.port}"

      "secure telnet" ->
        "#{connection.host}:#{connection.port}"
    end
  end
end

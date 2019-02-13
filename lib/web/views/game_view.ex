defmodule Web.GameView do
  use Web, :view

  alias Grapevine.Channels
  alias Grapevine.Games.Images
  alias Grapevine.Presence
  alias Grapevine.Storage
  alias Grapevine.UserAgents

  def cover_img_with_default(conn, game) do
    case has_cover?(game) do
      true ->
        cover_img(game)

      false ->
        default_cover_img(conn)
    end
  end

  def cover_img(game) do
    content_tag(:div, class: "cover") do
      [img_tag(Storage.url(Images.cover_path(game, "thumbnail"))), content_tag(:div, "", class: "shadow")]
    end
  end

  def default_cover_img(conn) do
    content_tag(:div, class: "cover") do
      [img_tag(static_path(conn, "/images/default-cover.png")), content_tag(:div, "", class: "shadow")]
    end
  end

  def has_cover?(game) do
    game.cover_key != nil
  end

  def play_button(conn, game) do
    case show_play_button?(game) do
      true ->
        web_connection =
          Enum.find(game.connections, fn connection ->
            connection.type == "web"
          end)

        case !is_nil(web_connection) do
          true ->
            link("Play", to: web_connection.url, target: "_blank", class: "btn btn-primary")

          false ->
            link("Play", to: play_path(conn, :show, game.short_name), class: "btn btn-primary")
        end

      false ->
        ""
    end
  end

  def show_play_button?(game) do
    game.enable_web_client && (telnet_connection?(game) || web_connection?(game))
  end

  defp telnet_connection?(game) do
    Enum.any?(game.connections, fn connection ->
      connection.type == "telnet"
    end)
  end

  defp web_connection?(game) do
    Enum.any?(game.connections, fn connection ->
      connection.type == "web"
    end)
  end

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

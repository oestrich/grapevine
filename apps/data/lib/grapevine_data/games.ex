defmodule GrapevineData.Games do
  @moduledoc """
  Context for games
  """

  alias GrapevineData.Accounts.User
  alias GrapevineData.Alerts
  alias GrapevineData.Filter
  alias GrapevineData.Games.Connection
  alias GrapevineData.Games.Game
  alias GrapevineData.Games.Images
  alias GrapevineData.Games.RedirectURI
  alias GrapevineData.Notifications
  alias GrapevineData.Repo
  alias GrapevineData.UserAgents

  import Ecto.Query

  @type id :: integer()
  @type game_params :: map()
  @type token :: String.t()
  @type game_name :: String.t()
  @type short_name :: String.t()
  @type uuid :: String.t()

  @doc """
  Start a new game
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Game{} |> Game.changeset(%{})

  @doc """
  Start to a edit game
  """
  @spec edit(Game.t()) :: Ecto.Changeset.t()
  def edit(game), do: game |> Game.changeset(%{})

  @doc """
  Get all games
  """
  def all() do
    Game
    |> order_by([g], g.name)
    |> preload([:connections, :redirect_uris])
    |> Repo.all()
  end

  def all_public() do
    Game
    |> where([g], g.display == true)
    |> Repo.all()
  end

  def public(opts) do
    opts = Enum.into(opts, %{})

    query =
      Game
      |> preload([:connections])
      |> where([g], g.display == true)
      |> sort_online()
      |> Filter.filter(opts[:filter], __MODULE__)

    Stein.Pagination.paginate(Repo, query, opts)
  end

  def featured() do
    Game
    |> where([g], g.display == true)
    |> where([g], not is_nil(g.featured_order))
    |> order_by([g], asc: g.featured_order)
    |> Repo.all()
  end

  def filter_on_attribute({"name", value}, query) do
    where(query, [g], ilike(g.name, ^"%#{value}%"))
  end

  def filter_on_attribute({"server", value}, query) do
    where(query, [g], g.user_agent == ^value)
  end

  def filter_on_attribute({"cover", "yes"}, query) do
    where(query, [g], not is_nil(g.cover_key))
  end

  def filter_on_attribute({"online", "yes"}, query) do
    active_cutoff = Timex.now() |> Timex.shift(minutes: -1)
    telnet_cutoff = Timex.now() |> Timex.shift(minutes: -90)

    where(query, [g], g.last_seen_at > ^active_cutoff or g.telnet_last_seen_at > ^telnet_cutoff)
  end

  def filter_on_attribute(_, query), do: query

  defp sort_online(query) do
    active_cutoff = Timex.now() |> Timex.shift(minutes: -1)
    telnet_cutoff = Timex.now() |> Timex.shift(minutes: -90)

    query
    |> order_by([g], fragment("coalesce(?, ?) > ? or coalesce(?, ?) > ? desc nulls last", g.last_seen_at, ^active_cutoff, ^active_cutoff, g.telnet_last_seen_at, ^telnet_cutoff, ^telnet_cutoff))
    |> order_by([g], g.name)
  end

  @doc """
  Get games for a user
  """
  @spec for_user(User.t()) :: [Game.t()]
  def for_user(user) do
    Game
    |> where([g], g.user_id == ^user.id)
    |> order_by([g], g.name)
    |> Repo.all()
  end

  @doc """
  Load all games with a cname
  """
  def with_cname() do
    Game
    |> where([g], not is_nil(g.client_cname) or not is_nil(g.site_cname))
    |> Repo.all()
  end

  @doc """
  Fetch a game
  """
  @spec get(id()) :: Game.t()
  def get(game_id) do
    case Repo.get(Game, game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, preload(game)}
    end
  end

  @doc """
  Fetch a game based on the user
  """
  @spec get(User.t(), id()) :: Game.t()
  def get(user, game_id) do
    case Repo.get_by(Game, user_id: user.id, id: game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, preload(game)}
    end
  end

  @doc """
  Fetch a game based on the user
  """
  def get_by(opts) do
    case Repo.get_by(Game, opts) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, preload(game)}
    end
  end

  @doc """
  Fetch a game by the short name
  """
  def get_by_short(short_name, opts \\ []) do
    case Repo.get_by(Game, Keyword.merge(opts, [short_name: short_name])) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, preload(game)}
    end
  end

  defp preload(game) do
    game
    |> Repo.preload([:client_settings, :connections, :gauges, :hosted_settings, :redirect_uris])
    |> preload_client_settings()
    |> preload_hosted_settings()
  end

  defp preload_client_settings(game = %{client_settings: nil}) do
    client_settings = Ecto.build_assoc(game, :client_settings)
    %{game | client_settings: client_settings}
  end

  defp preload_client_settings(game), do: game

  defp preload_hosted_settings(game = %{hosted_settings: nil}) do
    hosted_settings = Ecto.build_assoc(game, :hosted_settings)
    %{game | hosted_settings: hosted_settings}
  end

  defp preload_hosted_settings(game), do: game

  @doc """
  Get a game by it's CNAME

  This value must be set from the database
  """
  def get_by_host(host) do
    case get_by(client_cname: host, display: true) do
      {:ok, game} ->
        {:ok, game}

      {:error, :not_found} ->
        get_by(site_cname: host, display: true)
    end
  end

  @doc """
  Register a new game
  """
  @spec register(User.t(), game_params()) :: {:ok, Game.t()}
  def register(user, params) do
    changeset =
      user
      |> Ecto.build_assoc(:games)
      |> Game.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, game} ->
        Notifications.new_game(game)
        Images.maybe_upload_images(game, params)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a game
  """
  @spec update(Game.t(), game_params()) :: {:ok, Game.t()}
  def update(game, params) do
    changeset = game |> Game.changeset(params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        Images.maybe_upload_images(game, params)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Check if the web client is enabled
  """
  @spec check_web_client(Game.t()) :: {:ok, Game.t()} | {:error, :disabled_client}
  def check_web_client(game) do
    with true <- game.enable_web_client,
         {:ok, _connection} <- get_web_client_connection(game) do
      {:ok, game}
    else
      _ ->
        {:error, :disabled_client}
    end
  end

  @doc """
  Get the connection for a web client
  """
  def get_web_client_connection(game) do
    game = Repo.preload(game, [:connections])

    case get_secure_telnet_connection(game) do
      {:ok, connection} ->
        {:ok, connection}

      {:error, :not_found} ->
        get_telnet_connection(game)
    end
  end

  defp get_secure_telnet_connection(game) do
    secure_telnet =
      Enum.find(game.connections, fn connection ->
        connection.type == "secure telnet"
      end)

    case secure_telnet do
      nil ->
        {:error, :not_found}

      connection ->
        {:ok, connection}
    end
  end

  defp get_telnet_connection(game) do
    telnet =
      Enum.find(game.connections, fn connection ->
        connection.type == "telnet"
      end)

    case telnet do
      nil ->
        {:error, :not_found}

      connection ->
        {:ok, connection}
    end
  end

  @doc """
  Update a game
  """
  @spec regenerate_client_tokens(User.t(), id()) :: {:ok, Game.t()}
  def regenerate_client_tokens(user, id) do
    case Repo.get_by(Game, user_id: user.id, id: id) do
      nil ->
        {:error, :not_found}

      game ->
        changeset = game |> Game.regenerate_changeset()

        case Repo.update(changeset) do
          {:ok, game} ->
            {:ok, game}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Validate a socket
  """
  @spec validate_socket(uuid(), uuid()) :: {:ok, Game.t()} | {:error, :invalid}
  def validate_socket(client_id, client_secret, user_agent_params \\ %{}) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, client_secret} <- Ecto.UUID.cast(client_secret),
         {:ok, game} <- get_game(client_id),
         {:ok, game} <- validate_secret(game, client_secret) do
      record_metadata(game, user_agent_params)
    else
      _ ->
        {:error, :invalid}
    end
  end

  defp get_game(client_id) do
    case Repo.get_by(Game, client_id: client_id) do
      nil ->
        {:error, :invalid}

      game ->
        {:ok, game}
    end
  end

  defp validate_secret(game, client_secret) do
    case game.client_secret == client_secret do
      true ->
        {:ok, game}

      false ->
        {:error, :invalid}
    end
  end

  @doc """
  Record metadata about a game, from the socket or MSSP
  """
  def record_metadata(game, user_agent_params) do
    changeset = game |> Game.metadata_changeset(user_agent_params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        maybe_register_user_agent(game)
        {:ok, game}

      {:error, _} ->
        {:error, :invalid}
    end
  end

  defp maybe_register_user_agent(game) do
    case game.user_agent do
      nil ->
        :ok

      user_agent ->
        UserAgents.register_user_agent(user_agent)
    end
  end

  @doc """
  Get a list of all user agents currently in use
  """
  def user_agents_in_use() do
    Game
    |> select([g], g.user_agent)
    |> distinct(:user_agent)
    |> Repo.all()
  end

  @doc """
  Update the timestamp for a game's last seen status
  """
  def seen_on_socket(game, seen_at \\ Timex.now()) do
    game
    |> Game.seen_changeset(seen_at)
    |> Repo.update()
  end

  @doc """
  Update the timestamp for a game's last seen status
  """
  def seen_on_telnet(game, seen_at \\ Timex.now()) do
    game
    |> Game.seen_on_telnet_changeset(seen_at)
    |> Repo.update()
  end

  @doc """
  Get all telnet connections
  """
  def telnet_connections() do
    Connection
    |> where([c], c.type == "telnet")
    |> where([c], c.poll_enabled)
    |> preload([:game])
    |> Repo.all()
  end

  @doc """
  Check if a user can manage a connection
  """
  @spec user_owns_connection?(User.t(), Connection.t()) :: boolean()
  def user_owns_connection?(user, connection) do
    connection = Repo.preload(connection, :game)
    connection.game.user_id == user.id
  end

  @doc """
  Edit a connection
  """
  def edit_connection(connection) do
    Ecto.Changeset.change(connection)
  end

  @doc """
  Get a connection by an id
  """
  @spec get_connection(id()) :: {:ok, Connection.t()} | {:error, :not_found}
  def get_connection(id) do
    case Repo.get_by(Connection, id: id) do
      nil ->
        {:error, :not_found}

      connection ->
        {:ok, connection}
    end
  end

  @doc """
  Create a new game connection
  """
  def create_connection(game, params, fun) do
    changeset =
      game
      |> Ecto.build_assoc(:connections)
      |> Connection.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, connection} ->
        fun.(connection)
        {:ok, connection}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a game connection
  """
  def update_connection(connection, params, fun) do
    changeset = Connection.update_changeset(connection, params)

    case Repo.update(changeset) do
      {:ok, connection} ->
        fun.(connection)
        {:ok, connection}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete a game connection
  """
  def delete_connection(connection) do
    Repo.delete(connection)
  end

  @doc """
  Mark a connection as ready to poll
  """
  def connection_succeeded(connection) do
    connection
    |> Connection.poll_changeset(true)
    |> Repo.update()
  end

  @doc """
  Mark a connection as ready to poll
  """
  def connection_failed(connection, notification_opts \\ []) do
    message = "Could not connection to game #{connection.game_id}, connection: #{connection.id}"
    Alerts.create("Connection failed", message, notification_opts)
  end

  @doc """
  Mark a connection as having mssp
  """
  def connection_has_mssp(connection) do
    connection = Repo.preload(connection, :game)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:connection, Connection.mssp_changeset(connection, true))
      |> Ecto.Multi.update(:game, Game.graph_changeset(connection.game, true))
      |> Repo.transaction()

    case result do
      {:ok, %{connection: connection}} ->
        {:ok, connection}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Mark a connection as not having mssp
  """
  def connection_has_no_mssp(connection) do
    case connection.supports_mssp do
      true ->
        create_failed_mssp_alert(connection)

      false ->
        :ok
    end
  end

  defp create_failed_mssp_alert(connection) do
    Alerts.create("MSSP failed", "Could not detect MSSP for game #{connection.game_id}")
  end

  @doc """
  Check if a user can manage a redirect_uri
  """
  @spec user_owns_redirect_uri?(User.t(), RedirectURI.t()) :: boolean()
  def user_owns_redirect_uri?(user, redirect_uri) do
    redirect_uri = Repo.preload(redirect_uri, :game)
    redirect_uri.game.user_id == user.id
  end

  @doc """
  Get a redirect_uri by an id
  """
  @spec get_redirect_uri(id()) :: {:ok, Connection.t()} | {:error, :not_found}
  def get_redirect_uri(id) do
    case Repo.get_by(RedirectURI, id: id) do
      nil ->
        {:error, :not_found}

      redirect_uri ->
        {:ok, redirect_uri}
    end
  end

  @doc """
  Create a new redirect uri for a game
  """
  def create_redirect_uri(game, uri) do
    changeset =
      game
      |> Ecto.build_assoc(:redirect_uris)
      |> RedirectURI.changeset(uri)

    case Repo.insert(changeset) do
      {:ok, redirect_uri} ->
        {:ok, redirect_uri}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete a redirect uri from a game
  """
  def delete_redirect_uri(redirect_uri) do
    case Repo.delete(redirect_uri) do
      {:ok, redirect_uri} ->
        {:ok, redirect_uri}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Load the list of blocked game names

  File is in `priv/games/block-list.txt`

  This file is a newline separated list of downcased names
  """
  @spec name_blocklist() :: [game_name()]
  def name_blocklist() do
    blocklist = Path.join(:code.priv_dir(:grapevine_data), "games/block-list.txt")
    {:ok, blocklist} = File.read(blocklist)

    blocklist
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end
end

defmodule Gossip.Games do
  @moduledoc """
  Context for games
  """

  alias Gossip.Games.Game
  alias Gossip.Repo

  @type game_params :: map()
  @type token :: String.t()

  @doc """
  Start a new game
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Game{} |> Game.changeset(%{})

  @doc """
  Register a new game
  """
  @spec register(game_params()) :: {:ok, Game.t()}
  def register(params) do
    %Game{}
    |> Game.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Find a game by the token
  """
  @spec from_token(token()) :: {:ok, Game.t()} | {:error, :not_found}
  def from_token(token) do
    case Repo.get_by(Game, token: token) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, preload(game)}
    end
  end

  defp preload(game) do
    Repo.preload(game, [:subscribed_channels, :channels])
  end

  @doc """
  Validate a login
  """
  @spec validate_login(String.t(), String.t()) :: {:ok, Game.t()} | {:error, :invalid}
  def validate_login(email, password) do
    case Repo.get_by(Game, email: email) do
      nil ->
        Comeonin.Bcrypt.dummy_checkpw()
        {:error, :invalid}

      game ->
        check_password(game, password)
    end
  end

  defp check_password(game, password) do
    case Comeonin.Bcrypt.checkpw(password, game.password_hash) do
      true ->
        {:ok, game}

      false ->
        {:error, :invalid}
    end
  end

  @doc """
  Validate a socket
  """
  @spec validate_socket(String.t(), String.t()) :: {:ok, Game.t()} | {:error, :invalid}
  def validate_socket(client_id, client_secret, user_agent_params \\ %{}) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, client_secret} <- Ecto.UUID.cast(client_secret),
         {:ok, game} <- get_game(client_id),
         {:ok, game} <- validate_secret(game, client_secret) do
      record_user_agent(game, user_agent_params)
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

  defp record_user_agent(game, user_agent_params) do
    changeset = game |> Game.user_agent_changeset(user_agent_params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        {:ok, preload(game)}

      {:error, _} ->
        {:error, :invalid}
    end
  end
end

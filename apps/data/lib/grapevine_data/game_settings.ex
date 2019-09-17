defmodule GrapevineData.GameSettings do
  @moduledoc """
  Context for games
  """

  alias GrapevineData.GameSettings.ClientSettings
  alias GrapevineData.GameSettings.HostedSettings
  alias GrapevineData.Repo

  @doc """
  Edit the client settings
  """
  def edit_client_settings(game) do
    game = Repo.preload(game, [:client_settings])

    case is_nil(game.client_settings) do
      true ->
        game
        |> Ecto.build_assoc(:client_settings)
        |> ClientSettings.changeset(%{})

      false ->
        ClientSettings.changeset(game.client_settings, %{})
    end
  end

  @doc """
  Update web client settings for the game
  """
  def update_client_settings(game, params) do
    game = Repo.preload(game, [:client_settings])

    case is_nil(game.client_settings) do
      true ->
        game
        |> Ecto.build_assoc(:client_settings)
        |> ClientSettings.changeset(params)
        |> Repo.insert()

      false ->
        game.client_settings
        |> ClientSettings.changeset(params)
        |> Repo.update()
    end
  end

  @doc """
  Edit the hosted settings
  """
  def edit_hosted_settings(game) do
    game = Repo.preload(game, [:hosted_settings])

    case is_nil(game.hosted_settings) do
      true ->
        game
        |> Ecto.build_assoc(:hosted_settings)
        |> HostedSettings.changeset(%{})

      false ->
        HostedSettings.changeset(game.hosted_settings, %{})
    end
  end

  @doc """
  Update web hosted settings for the game
  """
  def update_hosted_settings(game, params) do
    game = Repo.preload(game, [:hosted_settings])

    case is_nil(game.hosted_settings) do
      true ->
        game
        |> Ecto.build_assoc(:hosted_settings)
        |> HostedSettings.changeset(params)
        |> Repo.insert()

      false ->
        game.hosted_settings
        |> HostedSettings.changeset(params)
        |> Repo.update()
    end
  end
end

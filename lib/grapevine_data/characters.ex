defmodule GrapevineData.Characters do
  @moduledoc """
  Characters context
  """

  import Ecto.Query

  alias GrapevineData.Characters.Character
  alias GrapevineData.Repo

  @type id :: integer()

  @doc """
  Get a character by id
  """
  @spec get(id()) :: {:ok, Character.t()} | {:error, :not_found}
  def get(id) do
    case Repo.get_by(Character, id: id) do
      nil ->
        {:error, :not_found}

      character ->
        {:ok, character}
    end
  end

  @doc """
  Get characters for a user
  """
  def for(user) do
    Character
    |> where([c], c.user_id == ^user.id)
    |> preload([:game])
    |> Repo.all()
  end

  @doc """
  Start character registration
  """
  def start_registration(user, game, name) do
    user
    |> Ecto.build_assoc(:characters)
    |> Character.create_changeset(game, name)
    |> Repo.insert()
  end

  @doc """
  Approve a character for display
  """
  def approve_character(character) do
    character
    |> Character.approve_changeset()
    |> Repo.update()
  end

  @doc """
  Deny a character for display
  """
  def deny_character(character) do
    character
    |> Character.deny_changeset()
    |> Repo.update()
  end

  @doc """
  Check if the user matches the character owner
  """
  def check_user(character, user) do
    case character.user_id == user.id do
      true ->
        {:ok, character}

      false ->
        {:error, :different_user}
    end
  end
end

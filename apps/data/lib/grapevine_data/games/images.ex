defmodule GrapevineData.Games.Images do
  @moduledoc """
  Handle uploading images to remote storage for games
  """

  alias GrapevineData.Games.Game
  alias GrapevineData.Images
  alias GrapevineData.Repo
  alias Stein.Storage

  @doc """
  If present, upload a cover and/or hero image for a game

  Only uploads a cover if the key "cover" is present, and only uploads
  a hero image if the key "hero" is present. Deletes previous images on
  new uploads.
  """
  def maybe_upload_images(game, params) do
    params = for {key, val} <- params, into: %{}, do: {to_string(key), val}

    with {:ok, game} <- maybe_upload_cover_image(game, params),
         {:ok, game} <- maybe_upload_hero_image(game, params) do
      {:ok, game}
    end
  end

  @doc """
  Get a storage path for uploading and viewing the cover image
  """
  def cover_path(game, size) do
    cover_path(game.id, size, game.cover_key, game.cover_extension)
  end

  defp cover_path(game_id, "thumbnail", key, extension) when extension != ".png" do
    cover_path(game_id, "thumbnail", key, ".png")
  end

  defp cover_path(game_id, size, key, extension) do
    "/" <> Path.join(["games", to_string(game_id), "cover", "#{size}-#{key}#{extension}"])
  end

  @doc """
  Get a storage path for uploading and viewing the hero image
  """
  def hero_path(game, size) do
    hero_path(game.id, size, game.hero_key, game.hero_extension)
  end

  defp hero_path(game_id, "thumbnail", key, extension) when extension != ".png" do
    hero_path(game_id, "thumbnail", key, ".png")
  end

  defp hero_path(game_id, size, key, extension) do
    "/" <> Path.join(["games", to_string(game_id), "hero", "#{size}-#{key}#{extension}"])
  end

  @doc """
  Delete the old images for the cover or hero

  Deletes original and thumbnail sizes if present.
  """
  def maybe_delete_old_images(game, key, path_fun) do
    case is_nil(Map.get(game, key)) do
      true ->
        game

      false ->
        Storage.delete(path_fun.(game, "original"))
        Storage.delete(path_fun.(game, "thumbnail"))

        game
    end
  end

  @doc """
  Generate an upload key
  """
  def generate_key(), do: UUID.uuid4()

  @doc """
  Upload the file to the path in storage
  """
  def upload(file, path) do
    Storage.upload(file, path, extensions: [".jpg", ".png"], public: true)
  end

  def maybe_upload_cover_image(game, %{"cover" => file}) do
    game = maybe_delete_old_images(game, :cover_key, &cover_path/2)

    file = Storage.prep_file(file)
    key = generate_key()
    path = cover_path(game.id, "original", key, file.extension)
    changeset = Game.cover_changeset(game, key, file.extension)

    with :ok <- upload(file, path),
         {:ok, game} <- Repo.update(changeset) do
      generate_cover_versions(game, file)
    else
      :error ->
        game
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:cover, "could not upload, please try again")
        |> Ecto.Changeset.apply_action(:update)
    end
  end

  def maybe_upload_cover_image(game, _), do: {:ok, game}

  @doc """
  Generate a thumbnail for the cover image
  """
  def generate_cover_versions(game, file) do
    path = cover_path(game, "thumbnail")

    case Images.convert(file, [extname: ".png", thumbnail: "600x400"]) do
      {:ok, temp_path} ->
        upload(%{path: temp_path}, path)
        {:ok, game}

      {:error, :convert} ->
        {:ok, game}
    end
  end

  @doc """
  If the `hero` param is available upload to storage
  """
  def maybe_upload_hero_image(game, %{"hero" => file}) do
    game = maybe_delete_old_images(game, :hero_key, &hero_path/2)

    file = Storage.prep_file(file)
    key = generate_key()
    path = hero_path(game.id, "original", key, file.extension)
    changeset = Game.hero_changeset(game, key, file.extension)

    with :ok <- upload(file, path),
         {:ok, game} <- Repo.update(changeset) do
      generate_hero_versions(game, file)
    else
      :error ->
        game
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:hero, "could not upload, please try again")
        |> Ecto.Changeset.apply_action(:update)
    end
  end

  def maybe_upload_hero_image(game, _), do: {:ok, game}

  @doc """
  Generate a thumbnail for the hero image
  """
  def generate_hero_versions(game, file) do
    path = hero_path(game, "thumbnail")

    case Images.convert(file, [extname: ".png", thumbnail: "600x400"]) do
      {:ok, temp_path} ->
        upload(%{path: temp_path}, path)
        {:ok, game}

      {:error, :convert} ->
        {:ok, game}
    end
  end

  @doc """
  Regenerate the cover image for a game
  """
  def regenerate_cover(game) do
    case Storage.download(cover_path(game, "original")) do
      {:ok, temp_path} ->
        generate_cover_versions(game, %{path: temp_path})
    end
  end
end

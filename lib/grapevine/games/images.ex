defmodule Grapevine.Games.Images do
  @moduledoc """
  Handle uploading images to remote storage for games
  """

  alias Grapevine.Games.Game
  alias Grapevine.Images
  alias Grapevine.Storage
  alias Grapevine.Repo

  def cover_path(game, size) do
    cover_path(game.id, size, game.cover_key, game.cover_extension)
  end

  defp cover_path(game_id, "thumbnail", key, extension) when extension != ".png" do
    cover_path(game_id, "thumbnail", key, ".png")
  end

  defp cover_path(game_id, size, key, extension) do
    Path.join(["games", to_string(game_id), "cover", "#{size}-#{key}#{extension}"])
  end

  def maybe_upload_images(game, params) do
    params = for {key, val} <- params, into: %{}, do: {to_string(key), val}
    maybe_upload_cover_image(game, params)
  end

  def maybe_delete_old_images(game) do
    case is_nil(game.cover_key) do
      true ->
        game

      false ->
        Storage.delete(cover_path(game, "original"))
        Storage.delete(cover_path(game, "thumbnail"))

        game
    end
  end

  def maybe_upload_cover_image(game, %{"cover" => file}) do
    game = maybe_delete_old_images(game)

    file = Storage.prep_file(file)

    key = UUID.uuid4()
    extension = Path.extname(file.path)

    path = cover_path(game.id, "original", key, extension)

    case Storage.upload(file, path, extensions: [".jpg", ".png"]) do
      :ok ->
        game
        |> Game.cover_changeset(key, extension)
        |> Repo.update()
        |> maybe_generate_cover_version(file)

      :error ->
        changeset =
          game
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:cover, "could not upload, please try again")
          |> Map.put(:action, :update)

        {:error, changeset}
    end
  end

  def maybe_upload_cover_image(game, _), do: {:ok, game}

  defp maybe_generate_cover_version({:ok, game}, file) do
    generate_cover_versions(game, file)
  end

  defp maybe_generate_cover_version(result, _file), do: result

  def generate_cover_versions(game, file) do
    path = cover_path(game, "thumbnail")

    case Images.convert(file, [extname: ".png", thumbnail: "600x400"]) do
      {:ok, temp_path} ->
        Storage.upload(%{path: temp_path}, path, extensions: [".png"])
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

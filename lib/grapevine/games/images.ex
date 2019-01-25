defmodule Grapevine.Games.Images do
  @moduledoc """
  Handle uploading images to remote storage for games
  """

  alias Grapevine.Games.Game
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

  def maybe_upload_cover_image(game, %{"cover" => file}) do
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

    {:ok, temp_path} = Briefly.create(extname: ".png")

    args = [file.path, "-thumbnail", "600x400^", "-gravity", "center", "-extent", "600x400", temp_path]

    case Porcelain.exec("convert", args) do
      %{status: 0} ->
        Storage.upload(%{path: temp_path}, path, extensions: [".png"])

        {:ok, game}

      _ ->
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

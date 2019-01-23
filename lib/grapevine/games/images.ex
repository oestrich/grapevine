defmodule Grapevine.Games.Images do
  @moduledoc """
  Handle uploading images to remote storage for games
  """

  alias Grapevine.Games.Game
  alias Grapevine.Storage
  alias Grapevine.Repo

  def cover_path(game, size) do
    cover_path(game.id, size, game.cover_key)
  end

  def cover_path(game_id, size, key) do
    Path.join(["games", to_string(game_id), "cover", "#{size}-#{key}.jpg"])
  end

  def maybe_upload_images(game, params) do
    params = for {key, val} <- params, into: %{}, do: {to_string(key), val}

    maybe_upload_cover_image(game, params)
  end

  def maybe_upload_cover_image(game, %{"cover" => file}) do
    key = UUID.uuid4()
    path = cover_path(game.id, "original", key)

    case Storage.upload(file, path, extensions: [".jpg", ".png", ".gif"]) do
      :ok ->
        game
        |> Game.cover_changeset(key)
        |> Repo.update()
        |> generate_cover_versions(file)

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

  def generate_cover_versions({:ok, game}, file) do
    path = cover_path(game.id, "thumbnail", game.cover_key)

    {:ok, temp_path} = Briefly.create(extname: ".jpg")

    case Porcelain.exec("convert", [file.path, "-resize", "300x200", temp_path]) do
      %{status: 0} ->
        Storage.upload(%{path: temp_path}, path, extensions: [".jpg"])

        {:ok, game}

      _ ->
        {:ok, game}
    end
  end

  def generate_cover_versions(result, _file), do: result
end

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
    Path.join(["games", to_string(game_id), "cover", "#{size}-#{key}.png"])
  end

  def maybe_upload_images(game, params) do
    params = for {key, val} <- params, into: %{}, do: {to_string(key), val}

    maybe_upload_cover_image(game, params)
  end

  def maybe_upload_cover_image(game, %{"cover" => file}) do
    key = UUID.uuid4()
    path = cover_path(game.id, "original", key)

    case Storage.upload(file, path) do
      :ok ->
        game
        |> Game.cover_changeset(key)
        |> Repo.update()

      :error ->
        game
    end
  end

  def maybe_upload_cover_image(game, _), do: {:ok, game}
end

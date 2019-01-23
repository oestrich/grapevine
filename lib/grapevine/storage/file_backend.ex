defmodule Grapevine.Storage.FileBackend do
  @moduledoc """
  File uploads
  """

  @behaviour Grapevine.Storage

  @impl true
  def upload(file, key) do
    path = Path.join(:code.priv_dir(:grapevine), "files/#{key}")
    File.copy(file, path)
  end
end

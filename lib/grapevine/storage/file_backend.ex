defmodule Grapevine.Storage.FileBackend do
  @moduledoc """
  File uploads
  """

  @behaviour Grapevine.Storage

  @impl true
  def delete(key) do
    path = Path.join(:code.priv_dir(:grapevine), "files/#{key}")
    File.rm(path)

    :ok
  end

  @impl true
  def download(key) do
    path = Path.join(:code.priv_dir(:grapevine), "files/#{key}")
    extname = Path.extname(path)
    {:ok, temp_path} = Briefly.create(extname: extname)
    File.copy(path, temp_path)
    {:ok, temp_path}
  end

  @impl true
  def upload(file, key) do
    path = Path.join(:code.priv_dir(:grapevine), "files/#{key}")

    dirname = Path.dirname(path)
    File.mkdir_p(dirname)

    case File.copy(file.path, path) do
      {:ok, _} ->
        :ok

      _ ->
        :error
    end
  end

  @impl true
  def url(key) do
    "/uploads/#{key}"
  end
end

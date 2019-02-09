defmodule Grapevine.Storage.S3Backend do
  @moduledoc """
  S3 uploads
  """

  alias ExAws.S3

  @behaviour Grapevine.Storage

  def bucket(), do: Application.get_env(:grapevine, :storage)[:bucket]

  @impl true
  def delete(key) do
    bucket()
    |> S3.delete_object(key)
    |> ExAws.request()

    :ok
  end

  @impl true
  def download(key) do
    extname = Path.extname(key)
    {:ok, temp_path} = Briefly.create(extname: extname)

    bucket()
    |> S3.download_file(key, temp_path)
    |> ExAws.request()

    {:ok, temp_path}
  end

  @impl true
  def upload(file, key) do
    meta = [
      {:cache_control, "public, max-age=2592000"},
      {:acl, :public_read}
    ]

    bucket()
    |> S3.put_object(key, File.read!(file.path), meta)
    |> ExAws.request!()

    :ok
  end

  @impl true
  def url(key) do
    "https://s3.amazonaws.com/#{bucket()}/#{key}"
  end
end

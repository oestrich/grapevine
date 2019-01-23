defmodule Grapevine.Storage.S3Backend do
  @moduledoc """
  S3 uploads
  """

  alias ExAws.S3

  @behaviour Grapevine.Storage

  def bucket(), do: Application.get_env(:grapevine, :storage)[:bucket]

  @impl true
  def upload(file, key) do
    meta = [
      {:cache_control, "public, max-age=25200"},
      {:content_type, "image/png"},
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

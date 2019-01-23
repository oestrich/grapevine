defmodule Grapevine.Storage.S3Backend do
  @moduledoc """
  S3 uploads
  """

  alias ExAws.S3

  @behaviour Grapevine.Storage

  @bucket Application.get_env(:grapevine, :storage)[:bucket]

  @impl true
  def upload(file, key) do
    meta = [
      {:cache_control, "public, max-age=25200"},
      {:content_type, "image/png"},
      {:acl, :public_read}
    ]

    @bucket
    |> S3.put_object(key, File.read!(file), meta)
    |> ExAws.request!
  end
end

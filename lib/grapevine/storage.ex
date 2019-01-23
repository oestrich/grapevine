defmodule Grapevine.Storage do
  @moduledoc """
  Handle storing files in the cloud or local file system
  """

  alias Grapevine.Storage.FileBackend
  alias Grapevine.Storage.S3Backend

  @backend Application.get_env(:grapevine, :storage)[:backend]

  @callback upload(file :: String.t(), key :: String.t()) :: :ok

  @doc """
  Upload files to the remote storage
  """
  def upload(file, key) do
    case @backend do
      :file ->
        FileBackend.upload(file, key)

      :s3 ->
        S3Backend.upload(file, key)
    end
  end
end

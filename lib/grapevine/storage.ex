defmodule Grapevine.Storage do
  @moduledoc """
  Handle storing files in the cloud or local file system
  """

  alias Grapevine.Storage.FileBackend
  alias Grapevine.Storage.MockBackend
  alias Grapevine.Storage.S3Backend

  @backend Application.get_env(:grapevine, :storage)[:backend]

  @type file :: String.t()
  @type key :: String.t()
  @type url :: String.t()

  @callback upload(file(), key()) :: :ok | :error

  @callback url(key()) :: url()

  @doc """
  Upload files to the remote storage
  """
  def upload(file, key) do
    backend().upload(file_path(file), key)
  end

  @doc """
  Get the remote url for viewing an uploaded file
  """
  def url(key) do
    backend().url(key)
  end

  @doc false
  def backend() do
    case @backend do
      :file ->
        FileBackend

      :s3 ->
        S3Backend

      :test ->
        MockBackend
    end
  end

  def file_path(upload = %Plug.Upload{}) do
    %{filename: upload.filename, path: upload.path}
  end

  def file_path(upload) when is_map(upload) do
    %{filename: Path.basename(upload.path), path: upload.path}
  end
end

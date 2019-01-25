defmodule Grapevine.Storage do
  @moduledoc """
  Handle storing files in the cloud or local file system
  """

  alias Grapevine.Storage.FileBackend
  alias Grapevine.Storage.FileUpload
  alias Grapevine.Storage.MockBackend
  alias Grapevine.Storage.S3Backend

  @backend Application.get_env(:grapevine, :storage)[:backend]

  @type file :: String.t()
  @type key :: String.t()
  @type path :: Path.t()
  @type url :: String.t()

  @callback delete(key()) :: :ok

  @callback download(key()) :: {:ok, path()}

  @callback upload(file(), key()) :: :ok | :error

  @callback url(key()) :: url()

  @doc """
  Delete files from remote storage
  """
  def delete(key) do
    backend().delete(key)
  end

  @doc """
  Download files from remote storage
  """
  def download(key) do
    backend().download(key)
  end

  @doc """
  Upload files to the remote storage
  """
  def upload(file, key, opts) do
    path = prep_file(file)

    with {:ok, :extension} <- check_extensions(path, opts) do
      backend().upload(path, key)
    end
  end

  defp check_extensions(file, opts) do
    allowed_extensions = Keyword.get(opts, :extensions, [])
    extension = String.downcase(Path.extname(file.filename))

    case extension in allowed_extensions do
      true ->
        {:ok, :extension}

      false ->
        :error
    end
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

  def prep_file(upload = %FileUpload{}), do: upload

  def prep_file(upload = %Plug.Upload{}) do
    %FileUpload{filename: upload.filename, path: upload.path}
  end

  def prep_file(upload) when is_map(upload) do
    %FileUpload{filename: Path.basename(upload.path), path: upload.path}
  end
end

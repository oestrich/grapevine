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
  @type path :: Path.t()
  @type url :: String.t()

  @callback download(key()) :: {:ok, path()}

  @callback upload(file(), key()) :: :ok | :error

  @callback url(key()) :: url()

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
    path = file_path(file)

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

  def file_path(upload = %Plug.Upload{}) do
    %{filename: upload.filename, path: upload.path}
  end

  def file_path(upload) when is_map(upload) do
    %{filename: Path.basename(upload.path), path: upload.path}
  end
end

defmodule GrapevineData.Images do
  @moduledoc """
  Common module for dealing with image conversion
  """

  @type opts() :: Keyword.t()

  alias Stein.Storage.FileUpload

  @doc """
  Convert an image file using image magick
  """
  @spec convert(FileUpload.t(), opts()) :: {:ok, Path.t()} | {:error, :convert}
  def convert(file, opts) do
    {:ok, temp_path} = Briefly.create(extname: Keyword.get(opts, :extname))

    case Porcelain.exec("convert", convert_args(file.path, temp_path, opts)) do
      %{status: 0} ->
        {:ok, temp_path}

      _ ->
        {:error, :convert}
    end
  end

  defp convert_args(file_path, temp_path, opts) do
    [file_path | opt_args(opts)] ++ [temp_path]
  end

  defp opt_args([]), do: []

  defp opt_args([opt | opts]) do
    case opt do
      {:thumbnail, size} ->
        ["-thumbnail", "#{size}^", "-gravity", "center", "-extent", size] ++ opt_args(opts)

      _ ->
        opt_args(opts)
    end
  end
end

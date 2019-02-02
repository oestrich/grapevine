defmodule Grapevine.Telnet.GMCP do
  @moduledoc """
  Parse GMCP messages
  """

  @doc """
  Parse GMCP messages
  """
  def parse(binary) do
    binary = strip(binary)

    [module | _] = String.split(binary, " ")
    data = String.replace(binary, module, "")
    data = String.trim(data)

    case Jason.decode(data) do
      {:ok, data} ->
        {:ok, module, data}

      _ ->
        :error
    end
  end

  @doc """
  Strip the final IAC SE
  """
  def strip(<<>>), do: <<>>

  def strip(<<255, 240>>), do: <<>>

  def strip(<<byte::size(8), data::binary>>) do
    <<byte>> <> strip(data)
  end
end

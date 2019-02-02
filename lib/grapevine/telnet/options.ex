defmodule Grapevine.Telnet.Options do
  @moduledoc """
  Parse telnet IAC options coming from the game
  """

  alias Grapevine.Telnet.GMCP
  alias Grapevine.Telnet.MSSP

  @se 240
  @nop 241
  @ga 249
  @sb 250
  @will 251
  @wont 252
  @iac_do 253
  @dont 254
  @iac 255

  @term_type 24
  @line_mode 34
  @charset 42
  @mssp 70
  @gmcp 201

  @charset_request 1
  @term_type_send 1

  def mssp_data?(options) do
    Enum.any?(options, fn option ->
      match?({:mssp, _}, option)
    end)
  end

  def text_mssp?(string) do
    string =~ "MSSP-REPLY-START"
  end

  def get_mssp_data(options) do
    Enum.find(options, fn option ->
      match?({:mssp, _}, option)
    end)
  end

  @doc """
  Parse binary data from a MUD into any telnet options found and known
  """
  def parse(binary) do
    {options, leftover} = options(binary, <<>>, [], binary)

    options =
      options
      |> Enum.reject(&(&1 == <<>>))
      |> Enum.map(&transform/1)

    string =
      options
      |> Enum.filter(&is_string?/1)
      |> Enum.map(&(elem(&1, 1)))
      |> Enum.join()

    options =
      options
      |> Enum.reject(&is_unknown_option?/1)
      |> Enum.reject(&is_string?/1)

    {options, string, strip_to_iac(leftover)}
  end

  defp is_unknown_option?(option), do: option == :unknown

  defp is_string?({:string, _}), do: true

  defp is_string?(_), do: false

  defp strip_to_iac(<<>>), do: <<>>

  defp strip_to_iac(<<@iac, data::binary>>), do: <<@iac>> <> data

  defp strip_to_iac(<<_byte::size(8), data::binary>>) do
    strip_to_iac(data)
  end

  @doc """
  Parse options out of a binary stream
  """
  def options(<<>>, current, stack, leftover) do
    {stack ++ [current], leftover}
  end

  def options(<<@iac, @sb, data::binary>>, current, stack, leftover) do
    case parse_sub_negotiation(<<@iac, @sb>> <> data) do
      :error ->
        options(data, current <> <<@iac, @sb>>, stack, leftover)

      {sub, data} ->
        options(data, <<>>, stack ++ [current, sub], data)
    end
  end

  def options(<<@iac, @will, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @will, byte>>], data)
  end

  def options(<<@iac, @wont, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @wont, byte>>], data)
  end

  def options(<<@iac, @iac_do, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @iac_do, byte>>], data)
  end

  def options(<<@iac, @dont, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @dont, byte>>], data)
  end

  def options(<<@iac, @ga, data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @ga>>], data)
  end

  def options(<<@iac, @nop, data::binary>>, current, stack, _leftover) do
    options(data, <<>>, stack ++ [current, <<@iac, @nop>>], data)
  end

  def options(<<@iac, data::binary>>, current, stack, leftover) do
    options(data, <<@iac>>, stack ++ [current], leftover)
  end

  def options(<<byte::size(8), data::binary>>, current, stack, leftover) do
    options(data, current <> <<byte>>, stack, leftover)
  end

  @doc """
  Parse sub negotiation options out of a stream
  """
  def parse_sub_negotiation(data, stack \\ <<>>)

  def parse_sub_negotiation(<<>>, _stack), do: :error

  def parse_sub_negotiation(<<byte::size(8), @iac, @se, data::binary>>, stack) do
    {stack <> <<byte, @iac, @se>>, data}
  end

  def parse_sub_negotiation(<<byte::size(8), data::binary>>, stack) do
    parse_sub_negotiation(data, stack <> <<byte>>)
  end

  @doc """
  Transform IAC binary data to actionable terms

      iex> Options.transform(<<255, 253, 42>>)
      {:do, :charset}

      iex> Options.transform(<<255, 253, 24>>)
      {:do, :term_type}

      iex> Options.transform(<<255, 253, 34>>)
      {:do, :line_mode}

      iex> Options.transform(<<255, 251, 42>>)
      {:will, :charset}

      iex> Options.transform(<<255, 251, 70>>)
      {:will, :mssp}

      iex> Options.transform(<<255, 252, 70>>)
      {:wont, :mssp}

      iex> Options.transform(<<255, 251, 201>>)
      {:will, :gmcp}

  Returns a generic DO/WILL if the specific term is not known. For
  responding with the opposite command to reject.

      iex> Options.transform(<<255, 251, 1>>)
      {:will, 1}

      iex> Options.transform(<<255, 252, 1>>)
      {:wont, 1}

      iex> Options.transform(<<255, 253, 1>>)
      {:do, 1}

      iex> Options.transform(<<255, 254, 1>>)
      {:dont, 1}

  Everything else is parsed as `:unknown`

      iex> Options.transform(<<255>>)
      :unknown
  """
  def transform(<<@iac, @iac_do, @term_type>>), do: {:do, :term_type}

  def transform(<<@iac, @iac_do, @line_mode>>), do: {:do, :line_mode}

  def transform(<<@iac, @iac_do, @charset>>), do: {:do, :charset}

  def transform(<<@iac, @iac_do, byte>>), do: {:do, byte}

  def transform(<<@iac, @dont, byte>>), do: {:dont, byte}

  def transform(<<@iac, @will, @mssp>>), do: {:will, :mssp}

  def transform(<<@iac, @will, @gmcp>>), do: {:will, :gmcp}

  def transform(<<@iac, @will, @charset>>), do: {:will, :charset}

  def transform(<<@iac, @will, byte>>), do: {:will, byte}

  def transform(<<@iac, @wont, @mssp>>), do: {:wont, :mssp}

  def transform(<<@iac, @wont, byte>>), do: {:wont, byte}

  def transform(<<@iac, @sb, @mssp, data::binary>>) do
    case MSSP.parse(<<@iac, @sb, @mssp, data::binary>>) do
      :error ->
        :unknown

      {:ok, data} ->
        {:mssp, data}
    end
  end

  def transform(<<@iac, @sb, @term_type, @term_type_send, @iac, @se>>) do
    {:send, :term_type}
  end

  def transform(<<@iac, @sb, @charset, @charset_request, sep::size(8), data::binary>>) do
    data = parse_charset(data)
    {:charset, :request, <<sep>>, data}
  end

  def transform(<<@iac, @sb, @gmcp, data::binary>>) do
    case GMCP.parse(data) do
      {:ok, module, data} ->
        {:gmcp, module, data}

      :error ->
        :unknown
    end
  end

  def transform(<<@iac, @sb, _data::binary>>) do
    :unknown
  end

  def transform(<<@iac, @ga>>), do: {:ga}

  def transform(<<@iac, @nop>>), do: {:nop}

  def transform(<<@iac, _byte::size(8)>>), do: :unknown

  def transform(<<@iac>>), do: :unknown

  def transform(binary), do: {:string, binary}

  @doc """
  Strip the final IAC SE from the charset
  """
  def parse_charset(<<@iac, @se>>) do
    <<>>
  end

  def parse_charset(<<byte::size(8), data::binary>>) do
    <<byte>> <> parse_charset(data)
  end
end

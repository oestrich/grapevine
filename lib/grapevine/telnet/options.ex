defmodule Grapevine.Telnet.Options do
  @moduledoc """
  Parse telnet IAC options coming from the game
  """

  alias Grapevine.Telnet.MSSP

  @se 240
  @sb 250
  @will 251
  @wont 252
  @iac_do 253
  @iac 255

  @term_type 24
  @line_mode 34
  @mssp 70
  @gmcp 201

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
    {options, leftover} = options(binary, [], [], binary)

    options =
      options
      |> Enum.reverse()
      |> Enum.map(&transform/1)
      |> Enum.reject(&is_unknown_option?/1)

    {options, strip_to_iac(leftover)}
  end

  defp is_unknown_option?(option), do: option == :unknown

  defp strip_to_iac(<<>>), do: <<>>

  defp strip_to_iac(<<@iac, data::binary>>), do: <<@iac>> <> data

  defp strip_to_iac(<<_byte::size(8), data::binary>>) do
    strip_to_iac(data)
  end

  @doc """
  Parse options out of a binary stream
  """
  def options(<<>>, current, stack, leftover) do
    {[Enum.reverse(current) | stack], leftover}
  end

  def options(<<@iac, @sb, data::binary>>, current, stack, leftover) do
    case parse_sub_negotiation(<<@iac, @sb>> <> data) do
      :error ->
        options(data, [@sb, @iac | current], stack, leftover)

      {sub, data} ->
        options(data, [], [sub, Enum.reverse(current) | stack], data)
    end
  end

  def options(<<@iac, @will, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, [], [[@iac, @will, byte], Enum.reverse(current) | stack], data)
  end

  def options(<<@iac, @iac_do, byte::size(8), data::binary>>, current, stack, _leftover) do
    options(data, [], [[@iac, @iac_do, byte], Enum.reverse(current) | stack], data)
  end

  def options(<<@iac, data::binary>>, current, stack, leftover) do
    options(data, [@iac], [Enum.reverse(current) | stack], leftover)
  end

  def options(<<byte::size(8), data::binary>>, current, stack, leftover) do
    options(data, [byte | current], stack, leftover)
  end

  @doc """
  Parse sub negotiation options out of a stream
  """
  def parse_sub_negotiation(data) do
    case sub_option(data, []) do
      :error ->
        :error

      {stack, data} ->
        {Enum.reverse(stack), data}
    end
  end

  def sub_option(<<>>, _stack), do: :error

  def sub_option(<<byte::size(8), @iac, @se, data::binary>>, stack) do
    {[@se, @iac, byte | stack], data}
  end

  def sub_option(<<byte::size(8), data::binary>>, stack) do
    sub_option(data, [byte | stack])
  end

  @doc """
  Transform IAC binary data to actionable terms

      iex> Options.transform([255, 253, 24])
      {:do, :term_type}

      iex> Options.transform([255, 253, 34])
      {:do, :line_mode}

      iex> Options.transform([255, 251, 70])
      {:will, :mssp}

      iex> Options.transform([255, 252, 70])
      {:wont, :mssp}

      iex> Options.transform([255, 251, 201])
      {:will, :gmcp}

  Returns a generic DO/WILL if the specific term is not known. For
  responding with the opposite command to reject.

      iex> Options.transform([255, 251, 1])
      {:will, 1}

      iex> Options.transform([255, 253, 1])
      {:do, 1}

  Everything else is parsed as `:unknown`

      iex> Options.transform([255])
      :unknown
  """
  def transform([@iac, @iac_do, @term_type]), do: {:do, :term_type}

  def transform([@iac, @iac_do, @line_mode]), do: {:do, :line_mode}

  def transform([@iac, @will, @mssp]), do: {:will, :mssp}

  def transform([@iac, @wont, @mssp]), do: {:wont, :mssp}

  def transform([@iac, @will, @gmcp]), do: {:will, :gmcp}

  def transform([@iac, @sb, @mssp | data]) when data != [] do
    case MSSP.parse([@iac, @sb, @mssp | data]) do
      :error ->
        :unknown

      {:ok, data} ->
        {:mssp, data}
    end
  end

  def transform([@iac, @iac_do, byte]), do: {:do, byte}

  def transform([@iac, @will, byte]), do: {:will, byte}

  def transform(_option), do: :unknown
end

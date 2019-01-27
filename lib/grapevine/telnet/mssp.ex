defmodule Grapevine.Telnet.MSSP do
  @moduledoc """
  Parse MSSP data

  Telnet option or plaintext
  """

  @se 240
  @iac 255

  @mssp_var 1
  @mssp_val 2

  @doc """
  Parse MSSP subnegotiation options
  """
  def parse(data) do
    case mssp(data, :start, []) do
      :error ->
        :error

      data ->
        data =
          data
          |> Enum.reject(&is_start?/1)
          |> Enum.into(%{}, fn map ->
            {to_string(Enum.reverse(map[:name])), to_string(Enum.reverse(map[:value]))}
          end)

        {:ok, data}
    end
  end

  defp is_start?(:start), do: true

  defp is_start?(_), do: false

  def mssp(<<>>, _current, _stack) do
    :error
  end

  def mssp(<<@iac, @se, _data::binary>>, current, stack) do
    [current | stack]
  end

  def mssp(<<@iac, data::binary>>, current, stack) do
    mssp(data, current, stack)
  end

  def mssp(<<@se, data::binary>>, current, stack) do
    mssp(data, current, stack)
  end

  def mssp(<<@mssp_var, data::binary>>, current, stack) do
    mssp(data, %{type: :name, name: [], value: []}, [current | stack])
  end

  def mssp(<<@mssp_val, data::binary>>, current, stack) do
    current =
      current
      |> Map.put(:type, :value)
      |> Map.put(:value_start, true)

    mssp(data, Map.put(current, :type, :value), stack)
  end

  def mssp(<<_byte::size(8), data::binary>>, :start, stack) do
    mssp(data, :start, stack)
  end

  def mssp(<<byte::size(8), data::binary>>, current, stack) do
    case current[:type] do
      :name ->
        mssp(data, Map.put(current, :name, [byte | current.name]), stack)

      :value ->
        mssp(data, append_value(current, byte), stack)
    end
  end

  defp append_value(current, byte) do
    case {current.value_start, current.value} do
      {true, []} ->
        current
        |> Map.put(:value, [byte | current.value])
        |> Map.put(:value_start, false)

      {true, value} ->
        current
        |> Map.put(:value, [byte, " ", "," | value])
        |> Map.put(:value_start, false)

      {false, value} ->
        Map.put(current, :value, [byte | value])
    end
  end

  @doc """
  Parse text as a response to `mssp-request`

  Should include MSSP-REPLY-START and end with MSSP-REPLY-END
  """
  def parse_text(text) do
    data =
      text
      |> String.replace("\r", "")
      |> String.split("\n")
      |> find_mssp_text([])

    case data do
      :error ->
        :error

      data ->
        Enum.into(data, %{}, &parse_mssp_text_line/1)
    end
  end

  def find_mssp_text([], _stack) do
    :error
  end

  def find_mssp_text(["MSSP-REPLY-START" | data], _stack) do
    find_mssp_text(data, [])
  end

  def find_mssp_text(["MSSP-REPLY-END" | _data], stack) do
    stack
  end

  def find_mssp_text([line | data], stack) do
    find_mssp_text(data, [line | stack])
  end

  def parse_mssp_text_line(line) do
    [name | values] = String.split(line, "\t")
    {name, Enum.join(values, "\t")}
  end
end

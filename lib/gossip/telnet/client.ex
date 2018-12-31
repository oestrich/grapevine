defmodule Gossip.Telnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer

  @iac 255
  @will 251

  alias Gossip.Telnet.Client.Options

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  defp send_term_type() do
    IO.inspect "Sending term type"
    GenServer.cast(self(), {:send_term_type})
  end

  defp record_mssp() do
    IO.inspect "requesting MSSP"
    GenServer.cast(self(), {:record_mssp})
  end

  def init(opts) do
    Process.send_after(self(), {:stop}, 15_000)

    {:ok, %{active: false, host: Keyword.get(opts, :host), port: Keyword.get(opts, :port)}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:ok, socket} = :gen_tcp.connect(String.to_charlist(state.host), state.port, [:binary, {:packet, 0}])
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_cast({:record_mssp}, state) do
    :gen_tcp.send(state.socket, <<@iac, 253, 70>>)
    {:noreply, state}
  end

  def handle_cast({:send_term_type}, state) do
    :gen_tcp.send(state.socket, <<@iac, @will, 24>>)
    :gen_tcp.send(state.socket, <<@iac, 250, 24, 0>> <> "Gossip" <> <<@iac, 240>>)
    {:noreply, state}
  end

  def handle_info({:stop}, state) do
    IO.inspect "terminating due to no mssp data"
    {:stop, :normal, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    IO.inspect Options.parse(data)

    cond do
      Options.supports_mssp?(data) ->
        record_mssp()
        {:noreply, state}

      Options.mssp_data?(data) ->
        data
        |> Options.parse()
        |> Enum.map(&Options.parse_mssp/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.reduce(%{}, fn mssp, map ->
          Map.merge(map, mssp)
        end)
        |> IO.inspect()

        {:stop, :normal, state}

      Options.term_type_request?(data) ->
        send_term_type()

        {:noreply, state}

      true ->
        {:noreply, state}
    end
  end

  defmodule Options do
    @moduledoc """
    Parse telnet IAC options coming from the game
    """

    @iac 255
    @sb 250
    @will 251

    @mssp 70

    def supports_mssp?(binary) do
      binary
      |> parse()
      |> Enum.member?([@iac, @will, 70])
    end

    def term_type_request?(binary) do
      binary
      |> parse()
      |> Enum.member?([@iac, 253, 24])
    end

    def mssp_data?(binary) do
      options = parse(binary)
      Enum.any?(options, fn option ->
        match?([@iac, 250, 70 | _], option)
      end)
    end

    def parse(binary) do
      binary
      |> options([], [])
      |> Enum.reverse()
      |> Enum.filter(&(List.first(&1) == @iac))
    end

    def options(<<>>, current, stack) do
      [Enum.reverse(current) | stack]
    end

    def options(<<@iac, 250, data :: binary>>, current, stack) do
      {sub, data} = parse_sub_negotiation(<<@iac, 250>> <> data)
      options(data, [], [sub, Enum.reverse(current) | stack])
    end

    def options(<<@iac, @will, byte :: size(8), data :: binary>>, current, stack) do
      options(data, [], [[@iac, @will, byte], Enum.reverse(current) | stack])
    end

    def options(<<@iac, 253, byte :: size(8), data :: binary>>, current, stack) do
      options(data, [], [[@iac, 253, byte], Enum.reverse(current) | stack])
    end

    def options(<<@iac, data :: binary>>, current, stack) do
      options(data, [@iac], [Enum.reverse(current) | stack])
    end

    def options(<<byte :: size(8), data :: binary>>, current, stack) do
      options(data, [byte | current], stack)
    end

    def parse_sub_negotiation(data) do
      {stack, data} = sub_option(data, [])
      {Enum.reverse(stack), data}
    end

    def sub_option(<<>>, stack), do: {stack, <<>>}

    def sub_option(<<byte :: size(8), @iac, 240, data :: binary>>, stack) do
      {[240, @iac, byte | stack], data}
    end

    def sub_option(<<byte :: size(8), data :: binary>>, stack) do
      sub_option(data, [byte | stack])
    end

    @doc """
    Parse MSSP subnegotiation options
    """
    def parse_mssp([@iac, @sb, @mssp | data]) do
      data
      |> mssp(nil, [])
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{}, fn map ->
        {to_string(Enum.reverse(map[:name])), to_string(Enum.reverse(map[:value]))}
      end)
    end

    def parse_mssp(_data), do: nil

    def mssp([], current, stack) do
      [current | stack]
    end

    def mssp([@iac | data], current, stack) do
      mssp(data, current, stack)
    end

    def mssp([240 | data], current, stack) do
      mssp(data, current, stack)
    end

    def mssp([1 | data], current, stack) do
      mssp(data, %{type: :name, name: [], value: []}, [current | stack])
    end

    def mssp([2 | data], current, stack) do
      mssp(data, Map.put(current, :type, :value), stack)
    end

    def mssp([byte | data], current, stack) do
      case current[:type] do
        :name ->
          mssp(data, Map.put(current, :name, [byte | current.name]), stack)

        :value ->
          mssp(data, Map.put(current, :value, [byte | current.value]), stack)

        _ ->
          mssp(data, current, stack)
      end
    end
  end
end

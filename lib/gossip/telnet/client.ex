defmodule Gossip.Telnet.Client do
  @moduledoc """
  A client to check for MSSP data
  """

  use GenServer

  require Logger

  @do_mssp <<255, 253, 70>>

  alias Gossip.Telnet
  alias Gossip.Telnet.Client.Options

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  defp record_mssp() do
    Logger.debug("Asking to send MSSP", type: :mssp)
    GenServer.cast(self(), {:record_mssp})
  end

  def init(opts) do
    Process.send_after(self(), {:stop}, 15_000)

    state = %{
      host: Keyword.get(opts, :host),
      port: Keyword.get(opts, :port),
      channel: Keyword.get(opts, :channel, nil),
      data: <<>>
    }

    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:ok, socket} = :gen_tcp.connect(String.to_charlist(state.host), state.port, [:binary, {:packet, 0}])
    {:noreply, Map.put(state, :socket, socket)}
  end

  def handle_cast({:record_mssp}, state) do
    :gen_tcp.send(state.socket, @do_mssp)
    {:noreply, state}
  end

  def handle_info({:stop}, state) do
    Logger.debug(fn ->
      "Terminating connection to #{state.host}:#{state.port} due to no MSSP being sent"
    end, type: :mssp)
    maybe_forward("mssp/terminated", %{}, state)
    Telnet.record_no_mssp(state.host, state.port)
    {:stop, :normal, state}
  end

  def handle_info({:tcp, _port, data}, state) do
    state = %{state | data: state.data <> data}
    options = Options.parse(state.data)

    cond do
      Options.will_mssp?(options) ->
        record_mssp()
        {:noreply, %{state | data: <<>>}}

      Options.mssp_data?(options) ->
        {:mssp, data} = Options.get_mssp_data(options)
        Logger.info("Received MSSP from #{state.host}:#{state.port} - #{inspect(data)}", type: :mssp)
        maybe_forward("mssp/received", data, state)
        Telnet.record_mssp_response(state.host, state.port, data)
        {:stop, :normal, state}

      true ->
        {:noreply, state}
    end
  end

  defp maybe_forward(event, message, state) do
    case state.channel do
      nil ->
        :ok

      channel ->
        Web.Endpoint.broadcast("mssp:#{channel}", event, message)
    end
  end

  defmodule Options do
    @moduledoc """
    Parse telnet IAC options coming from the game
    """

    @se 240
    @sb 250
    @will 251
    @wont 252
    @iac_do 253
    @iac 255

    @mssp 70
    @mssp_var 1
    @mssp_val 2

    def will_mssp?(options) do
      Enum.member?(options, {:will, :mssp})
    end

    def mssp_data?(options) do
      Enum.any?(options, fn option ->
        match?({:mssp, _}, option)
      end)
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
      binary
      |> options([], [])
      |> Enum.reverse()
      |> Enum.map(&transform/1)
      |> Enum.reject(&is_nil/1)
    end

    def transform(option) do
      case option do
        [@iac, @will, @mssp] ->
          {:will, :mssp}

        [@iac, @wont, @mssp] ->
          {:wont, :mssp}

        [@iac, @sb, @mssp | data] when data != [] ->
          {:mssp, parse_mssp(data)}

        _ ->
          nil
      end
    end

    @doc """
    Parse options out of a binary stream
    """
    def options(<<>>, current, stack) do
      [Enum.reverse(current) | stack]
    end

    def options(<<@iac, @sb, data :: binary>>, current, stack) do
      {sub, data} = parse_sub_negotiation(<<@iac, @sb>> <> data)
      options(data, [], [sub, Enum.reverse(current) | stack])
    end

    def options(<<@iac, @will, byte :: size(8), data :: binary>>, current, stack) do
      options(data, [], [[@iac, @will, byte], Enum.reverse(current) | stack])
    end

    def options(<<@iac, @iac_do, byte :: size(8), data :: binary>>, current, stack) do
      options(data, [], [[@iac, @iac_do, byte], Enum.reverse(current) | stack])
    end

    def options(<<@iac, data :: binary>>, current, stack) do
      options(data, [@iac], [Enum.reverse(current) | stack])
    end

    def options(<<byte :: size(8), data :: binary>>, current, stack) do
      options(data, [byte | current], stack)
    end

    @doc """
    Parse sub negotiation options out of a stream
    """
    def parse_sub_negotiation(data) do
      {stack, data} = sub_option(data, [])
      {Enum.reverse(stack), data}
    end

    def sub_option(<<>>, stack), do: {stack, <<>>}

    def sub_option(<<byte :: size(8), @iac, @se, data :: binary>>, stack) do
      {[byte | stack], data}
    end

    def sub_option(<<byte :: size(8), data :: binary>>, stack) do
      sub_option(data, [byte | stack])
    end

    @doc """
    Parse MSSP subnegotiation options
    """
    def parse_mssp(data) do
      data
      |> mssp(nil, [])
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{}, fn map ->
        {to_string(Enum.reverse(map[:name])), to_string(Enum.reverse(map[:value]))}
      end)
    end

    def mssp([], current, stack) do
      [current | stack]
    end

    def mssp([@iac | data], current, stack) do
      mssp(data, current, stack)
    end

    def mssp([@se | data], current, stack) do
      mssp(data, current, stack)
    end

    def mssp([@mssp_var | data], current, stack) do
      mssp(data, %{type: :name, name: [], value: []}, [current | stack])
    end

    def mssp([@mssp_val | data], current, stack) do
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

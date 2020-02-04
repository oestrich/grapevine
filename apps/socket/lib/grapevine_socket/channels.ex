defmodule GrapevineSocket.Channels do
  @moduledoc """
  Local channel sync
  """

  use GenServer

  alias GrapevineSocket.Channels.Implementation
  alias GrapevineSocket.PubSub

  @doc """
  Check if a channel is paused
  """
  def paused?(channel) do
    GenServer.call({:global, __MODULE__}, {:paused?, channel})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    create_table()
    {:ok, %{}, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, state) do
    subscribe()
    {:noreply, state}
  end

  def handle_info({:subscribe, count}, state) when count < 10 do
    subscribe(count)
    {:noreply, state}
  end

  def handle_info(%{topic: "system:channels", event: "pause", payload: payload}, state) do
    Implementation.pause_channel(payload)

    {:noreply, state}
  end

  def handle_call({:paused?, channel}, _from, state) do
    paused? =
      case :ets.lookup(__MODULE__, channel) do
        [{^channel, metadata}] ->
          Timex.before?(Timex.now(), metadata.paused_until)

        [] ->
          false
      end

    {:reply, paused?, state}
  end

  defp create_table() do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end

  # Local development does _not_ start the pubsub server, so this
  # application is started before pubsub is alive, so poll until it's alive
  defp subscribe(count \\ 0) do
    case is_nil(Process.whereis(Grapevine.PubSub)) do
      true ->
        Process.send_after(self(), {:subscribe, count + 1}, 250)

      false ->
        PubSub.subscribe("system:channels")
    end
  end

  defmodule Implementation do
    @moduledoc false

    alias GrapevineSocket.Channels

    def pause_channel(payload) do
      metadata = channel_metadata(payload.channel)

      paused_until = Timex.shift(Timex.now(), minutes: payload.minutes)
      metadata = Map.put(metadata, :paused_until, paused_until)

      :ets.insert(Channels, {payload.channel, metadata})
    end

    def channel_metadata(channel) do
      case :ets.lookup(Channels, channel) do
        [{^channel, metadata}] ->
          metadata

        [] ->
          %{}
      end
    end
  end
end

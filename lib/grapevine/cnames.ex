defmodule Grapevine.CNAMEs do
  @moduledoc """
  Sets up and handles reloads for any CNAMEs for the app
  """

  use GenServer

  alias Grapevine.Games

  @ets_key :cnames

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def reload() do
    GenServer.call(__MODULE__, {:reload})
  end

  @doc """
  Check if the hostname is known
  """
  def host_known?(host) do
    case :ets.lookup(@ets_key, host) do
      [{^host, _}] ->
        true

      _ ->
        false
    end
  end

  def init(_) do
    create_table()
    {:ok, %{}, {:continue, :setup_ets}}
  end

  def handle_continue(:setup_ets, state) do
    Enum.each(Games.with_cname(), fn game ->
      :ets.insert(@ets_key, {game.cname, game.id})
    end)

    {:noreply, state}
  end

  def handle_call({:reload}, _from, state) do
    {:noreply, state} = handle_continue(:setup_ets, state)
    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end
end

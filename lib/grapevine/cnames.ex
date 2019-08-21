defmodule Grapevine.CNAMEs do
  @moduledoc """
  Sets up and handles reloads for any CNAMEs for the app
  """

  use GenServer

  alias GrapevineData.Games

  @ets_key :cnames

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def reload() do
    GenServer.call(__MODULE__, {:reload})
  end

  @doc """
  Look up what type of CNAME the hostname is
  """
  def type_of_host(host) do
    case :ets.lookup(@ets_key, host) do
      [{^host, type, game_id}] ->
        {:ok, type, game_id}

      _ ->
        {:error, :not_found}
    end
  end

  def init(_) do
    create_table()
    {:ok, %{}, {:continue, :setup_ets}}
  end

  def handle_continue(:setup_ets, state) do
    Enum.each(Games.with_cname(), &load_game/1)

    {:noreply, state}
  end

  defp load_game(game) do
    if game.site_cname do
      :ets.insert(@ets_key, {game.site_cname, :site, game.id})
    end

    if game.client_cname do
      :ets.insert(@ets_key, {game.client_cname, :client, game.id})
    end
  end

  def handle_call({:reload}, _from, state) do
    {:noreply, state} = handle_continue(:setup_ets, state)
    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end
end

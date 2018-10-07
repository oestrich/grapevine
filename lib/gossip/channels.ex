defmodule Gossip.Channels do
  @moduledoc """
  Context for channels
  """

  import Ecto.Query

  alias Gossip.Channels.Channel
  alias Gossip.Repo

  @type opts :: Keyword.t()
  @type name :: String.t()

  @doc """
  Create a new channel
  """
  @spec create(map()) :: {:ok, Channel.t()}
  def create(attributes) do
    changeset = %Channel{} |> Channel.changeset(attributes)

    case Repo.insert(changeset) do
      {:ok, channel} ->
        Web.Endpoint.broadcast("system:backbone", "channels/new", channel)
        {:ok, channel}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Ensure a channel exists
  """
  @spec ensure_channel(name()) :: {:ok, name()} | {:error, name()}
  def ensure_channel(name) do
    case Repo.get_by(Channel, name: name) do
      nil ->
        case create(%{name: name}) do
          {:ok, channel} ->
            {:ok, channel.name}

          {:error, _} ->
            {:error, name}
        end

      channel ->
        {:ok, channel.name}
    end
  end

  @doc """
  Get all channels
  """
  @spec all(opts()) :: [Channel.t()]
  def all(opts \\ []) do
    Channel
    |> maybe_include_hidden(opts)
    |> Repo.all()
  end

  defp maybe_include_hidden(query, opts) do
    case Keyword.get(opts, :include_hidden, false) do
      false ->
        query |> where([c], c.hidden == false)

      true ->
        query
    end
  end

  @doc """
  Get a channel by name
  """
  @spec get(name()) :: {:ok, Channel.t} | {:error, :not_found}
  def get(channel) do
    case Repo.get_by(Channel, name: channel) do
      nil ->
        {:error, :not_found}

      channel ->
        {:ok, channel}
    end
  end

  @doc """
  Load the list of blocked channel names

  File is in `priv/channels/block-list.txt`

  This file is a newline separated list of downcased names
  """
  @spec name_blocklist() :: [name()]
  def name_blocklist() do
    blocklist = Path.join(:code.priv_dir(:gossip), "channels/block-list.txt")
    {:ok, blocklist} = File.read(blocklist)

    blocklist
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end
end

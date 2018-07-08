defmodule Gossip.Channels do
  @moduledoc """
  Context for channels
  """

  import Ecto.Query

  alias Gossip.Channels.Channel
  alias Gossip.Repo

  @type name :: String.t()

  @doc """
  Create a new channel
  """
  @spec create(map()) :: {:ok, Channel.t()}
  def create(attributes) do
    %Channel{}
    |> Channel.changeset(attributes)
    |> Repo.insert()
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
  @spec all() :: [Channel.t()]
  def all() do
    Channel
    |> where([c], c.hidden == false)
    |> Repo.all()
  end

  def get(channel) do
    case Repo.get_by(Channel, name: channel) do
      nil ->
        {:error, :not_found}

      channel ->
        {:ok, channel}
    end
  end
end

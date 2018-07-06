defmodule Gossip.Channels do
  @moduledoc """
  Context for channels
  """

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
  @spec ensure_channel(name()) :: name()
  def ensure_channel(name) do
    case Repo.get_by(Channel, name: name) do
      nil ->
        create(%{name: name})
        name

      _channel ->
        name
    end
  end

  @doc """
  Get all channels
  """
  @spec all() :: [Channel.t()]
  def all() do
    Repo.all(Channel)
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

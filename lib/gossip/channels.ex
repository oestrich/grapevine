defmodule Gossip.Channels do
  @moduledoc """
  Context for channels
  """

  alias Gossip.Channels.Channel
  alias Gossip.Channels.SubscribedChannel
  alias Gossip.Games.Game
  alias Gossip.Repo

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

  @doc """
  Update a game's channel subscriptions
  """
  def subscribe_to_channels(user, game_id, channel_ids) do
    case Repo.get_by(Game, user_id: user.id, id: game_id) do
      nil ->
        :error
      game ->
        game = Repo.preload(game, :subscribed_channels)

        channel_ids = Enum.map(channel_ids, &to_integer/1)
        subscribed_ids = Enum.map(game.subscribed_channels, &(&1.channel_id))

        _subscribe_to_channels(game, channel_ids, subscribed_ids)
        unsubscribe_to_channels(game, channel_ids, subscribed_ids)

        game = Repo.preload(game, :subscribed_channels, [force: true])
        {:ok, game}
    end
  end

  defp to_integer(channel_id) when is_binary(channel_id) do
    String.to_integer(channel_id)
  end

  defp to_integer(channel_id), do: channel_id

  defp _subscribe_to_channels(game, channel_ids, subscribed_ids) do
    channel_ids
    |> Enum.reject(&Enum.member?(subscribed_ids, &1))
    |> Enum.map(&create_subscription(game, &1))
  end

  defp create_subscription(game, channel_id) do
    game
    |> Ecto.build_assoc(:subscribed_channels)
    |> SubscribedChannel.changeset(%{channel_id: channel_id})
    |> Repo.insert()
  end

  defp unsubscribe_to_channels(game, channel_ids, subscribed_ids) do
    subscribed_ids
    |> Enum.reject(&Enum.member?(channel_ids, &1))
    |> Enum.map(&remove_subcription(game, &1))
  end

  defp remove_subcription(game, channel_id) do
    channel = Enum.find(game.subscribed_channels, &(&1.channel_id == channel_id))
    Repo.delete(channel)
  end
end

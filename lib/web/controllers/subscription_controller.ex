defmodule Web.SubscriptionController do
  use Web, :controller

  alias Gossip.Channels

  plug Web.Plugs.VerifyUser

  def update(conn, %{"id" => id, "game" => %{"subscriptions" => channel_ids}}) do
    %{current_user: user} = conn.assigns

    game = Enum.find(user.games, &(to_string(&1.id) == id))
    channel_ids = Enum.reject(channel_ids, &(&1 == ""))

    case Channels.subscribe_to_channels(game, channel_ids) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Subscriptions updated!")
        |> redirect(to: game_path(conn, :index))
    end
  end
end

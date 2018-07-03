defmodule Web.SubscriptionController do
  use Web, :controller

  alias Gossip.Channels

  plug Web.Plugs.VerifyUser

  def update(conn, %{"game" => %{"subscriptions" => channel_ids}}) do
    %{current_game: game} = conn.assigns

    channel_ids = Enum.reject(channel_ids, &(&1 == ""))

    case Channels.subscribe_to_channels(game, channel_ids) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Subscriptions updated!")
        |> redirect(to: config_path(conn, :show))
    end
  end
end

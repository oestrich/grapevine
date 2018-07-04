defmodule Web.SubscriptionController do
  use Web, :controller

  alias Gossip.Channels

  plug Web.Plugs.VerifyUser

  def update(conn, %{"id" => id, "game" => %{"subscriptions" => channel_ids}}) do
    %{current_user: user} = conn.assigns

    channel_ids = Enum.reject(channel_ids, &(&1 == ""))

    case Channels.subscribe_to_channels(user, id, channel_ids) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Subscriptions updated!")
        |> redirect(to: user_game_path(conn, :index))

      :error ->
        conn
        |> put_flash(:info, "Could not update subscriptions.")
        |> redirect(to: user_game_path(conn, :index))
    end
  end
end

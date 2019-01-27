defmodule Web.UserSocket do
  use Phoenix.Socket

  alias Grapevine.Accounts

  channel("chat:*", Web.ChatChannel)
  channel("mssp:*", Web.MSSPChannel)
  channel("play:client", Web.PlayChannel)

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 86_400) do
      {:ok, user_id} ->
        {:ok, user} = Accounts.get(user_id)
        {:ok, assign(socket, :user, user)}

      {:error, _reason} ->
        {:ok, socket}
    end
  end

  def id(_socket), do: nil
end

defmodule Web.UserSocket do
  use Phoenix.Socket

  channel("channels:*", Web.ChatChannel)
  channel("mssp:*", Web.MSSPChannel)

  def connect(_params, socket) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end

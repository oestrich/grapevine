defmodule Test.FakeClient do
  @moduledoc """
  Fake client
  """

  @behaviour Grapevine.Client

  @impl true
  def broadcast(message) do
    send(self(), {:broadcast, message})

    :ok
  end

  @impl true
  def send_tell(to_game, to_player, message) do
    send(self(), {:tell, {to_game, to_player, message}})

    :ok
  end
end

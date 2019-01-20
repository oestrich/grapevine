defmodule Test.FakeClient do
  @moduledoc """
  Fake client
  """

  def send_tell(to_game, to_player, message) do
    send(self(), {:tell, {to_game, to_player, message}})

    :ok
  end
end

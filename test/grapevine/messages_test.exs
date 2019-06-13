defmodule Grapevine.MessagesTest do
  use Grapevine.DataCase

  alias Grapevine.Messages

  describe "log a message" do
    test "successful" do
      game = TestHelpers.create_game(TestHelpers.create_user())
      channel = TestHelpers.create_channel()

      {:ok, message} =
        Messages.create(game, channel, %{
          name: "player",
          text: "howdy"
        })

      assert message.game_id == game.id
      assert message.channel_id == channel.id
      assert message.name == "player"
      assert message.text == "howdy"
    end
  end
end

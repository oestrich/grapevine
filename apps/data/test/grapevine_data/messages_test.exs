defmodule GrapevineData.MessagesTest do
  use Grapevine.DataCase

  alias GrapevineData.Messages

  describe "log a message" do
    test "from the socket" do
      game = TestHelpers.create_game(TestHelpers.create_user())
      channel = TestHelpers.create_channel()

      {:ok, message} =
        Messages.record_socket(game, channel, %{
          name: "player",
          text: "howdy"
        })

      assert message.game_id == game.id
      assert message.channel_id == channel.id

      assert message.channel == channel.name
      assert message.game == game.short_name
      assert message.name == "player"
      assert message.text == "howdy"
    end

    test "from the web" do
      user = TestHelpers.create_user()
      channel = TestHelpers.create_channel()

      {:ok, message} = Messages.record_web(channel, user, "howdy")

      assert message.user_id == user.id
      assert message.channel_id == channel.id

      assert message.channel == channel.name
      assert message.game == "Grapevine"
      assert message.name == user.username
      assert message.text == "howdy"
    end
  end
end

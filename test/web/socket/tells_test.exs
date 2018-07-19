defmodule Web.Socket.TellsTest do
  use ExUnit.Case

  alias Web.Socket.Tells

  doctest Tells

  describe "validate a send payload" do
    test "all valid" do
      payload = %{
        "from" => "Player",
        "game" => "ExVenture",
        "player" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      assert Tells.valid_payload?(payload)
    end

    test "missing fields" do
      payload = %{
        "from" => "Player",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "all strings" do
      payload = %{
        "from" => 1,
        "game" => nil,
        "player" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "sent_at is formatted properly" do
      payload = %{
        "from" => "Player",
        "game" => "ExVenture",
        "player" => "eric",
        "sent_at" => "2018-07-17T13:12:28-0400",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end
  end
end

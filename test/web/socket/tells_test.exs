defmodule Web.Socket.TellsTest do
  use ExUnit.Case

  alias Web.Socket.Tells

  doctest Tells

  describe "validate a send payload" do
    test "all valid" do
      payload = %{
        "from_name" => "Player",
        "to_game" => "ExVenture",
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      assert Tells.valid_payload?(payload)
    end

    test "missing fields" do
      payload = %{
        "from_name" => "Player",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "all strings" do
      payload = %{
        "from_name" => 1,
        "to_game" => nil,
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28Z",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end

    test "sent_at is formatted properly" do
      payload = %{
        "from_name" => "Player",
        "to_game" => "ExVenture",
        "to_name" => "eric",
        "sent_at" => "2018-07-17T13:12:28-0400",
        "message" => "hi"
      }

      refute Tells.valid_payload?(payload)
    end
  end
end

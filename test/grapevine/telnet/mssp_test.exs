defmodule Grapevine.Telnet.MSSPTest do
  use ExUnit.Case

  alias Grapevine.Telnet.MSSP

  describe "parsing MSSP variables" do
    test "pulls out variable names and values" do
      options = [
        1,
        78,
        65,
        77,
        69,
        2,
        69,
        120,
        86,
        101,
        110,
        116,
        117,
        114,
        101,
        32,
        77,
        85,
        68,
        1,
        80,
        76,
        65,
        89,
        69,
        82,
        83,
        2,
        48,
        1,
        85,
        80,
        84,
        73,
        77,
        69,
        2,
        49,
        53,
        52,
        54,
        49,
        50,
        56,
        54,
        55,
        50
      ]

      values = MSSP.parse(options)

      assert values["NAME"] == "ExVenture MUD"
    end

    test "multiple values" do
      options = <<1>> <> "NAME" <> <<2>> <> "ExVenture" <> <<2>> <> "MUD"
      options = String.to_charlist(options)

      values = MSSP.parse(options)

      assert values["NAME"] == "ExVenture, MUD"
    end
  end

  describe "parsing mssp text data" do
    test "start and end" do
      text = """
      MSSP-REPLY-START
      NAME\tGame
      MSSP-REPLY-END
      """

      values = MSSP.parse_text(text)

      assert values["NAME"] == "Game"
    end

    test "no end" do
      text = """
      MSSP-REPLY-START
      NAME\tGame
      """

      assert MSSP.parse_text(text) == :error
    end

    test "extra text included" do
      text = """
      Welcome to the game
      MSSP-REPLY-START
      NAME\tGame
      MSSP-REPLY-END
      Left over
      """

      values = MSSP.parse_text(text)

      assert values["NAME"] == "Game"
    end
  end
end

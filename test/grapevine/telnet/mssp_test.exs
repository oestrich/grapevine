defmodule Grapevine.Telnet.MSSPTest do
  use ExUnit.Case

  alias Grapevine.Telnet.MSSP

  describe "parsing MSSP variables" do
    test "pulls out variable names and values" do
      options = <<255, 250, 1>> <> "NAME" <> <<2>> <> "ExVenture MUD"
      options = options <> <<1>> <> "PLAYERS" <> <<2>> <> "0"
      options = options <> <<1>> <> "UPTIME" <> <<2>> <> "1546128672" <> <<255, 240>>

      options = :binary.bin_to_list(options)

      {:ok, values} = MSSP.parse(options)

      assert values["NAME"] == "ExVenture MUD"
    end

    test "handles invalid/not complete MSSP sequenence" do
      options = :binary.bin_to_list(<<255, 250, 1>> <> "NAME")

      assert :error = MSSP.parse(options)
    end

    test "multiple values" do
      options = <<255, 250, 1>> <> "NAME" <> <<2>> <> "ExVenture" <> <<2>> <> "MUD" <> <<255, 240>>
      options = :binary.bin_to_list(options)

      {:ok, values} = MSSP.parse(options)

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

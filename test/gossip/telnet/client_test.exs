defmodule Gossip.Telnet.ClientTest do
  use ExUnit.Case

  alias Gossip.Telnet.Client

  describe "parsing telnet options" do
    test "a string" do
      [] = Client.Options.parse("this is a string")
    end

    test "a single option" do
      [will: :mssp] = Client.Options.parse(<<255, 251, 70>>)
    end

    test "multiple options" do
      [will: :mssp] = Client.Options.parse(<<255, 251, 70, 255, 251, 201, 255, 251, 91>>)
    end

    test "parsing sub negotitation" do
      options = <<255, 250, 70, 1>> <> "name" <> <<2>> <> "gossip" <> <<255, 240, 85>>

      [mssp: %{"name" => "gossip"}] = Client.Options.parse(options)
    end

    test "sub negotiation options" do
      options =
        <<255, 250, 70, 1, 78, 65, 77, 69, 2, 69, 120, 86, 101, 110, 116, 117, 114, 101,
         32, 77, 85, 68, 1, 80, 76, 65, 89, 69, 82, 83, 2, 48, 1, 85, 80, 84, 73, 77,
         69, 2, 49, 53, 52, 54, 49, 50, 56, 54, 55, 50, 255, 240, 85>>

      {sub, <<85>>} = Client.Options.parse_sub_negotiation(options)

      assert [255, 250 | _] = sub
    end
  end

  describe "parsing MSSP variables" do
    test "pulls out variable names and values" do
      options =
        [1, 78, 65, 77, 69, 2, 69, 120, 86, 101, 110, 116, 117, 114, 101,
         32, 77, 85, 68, 1, 80, 76, 65, 89, 69, 82, 83, 2, 48, 1, 85, 80, 84, 73, 77,
         69, 2, 49, 53, 52, 54, 49, 50, 56, 54, 55, 50]

      values = Client.Options.parse_mssp(options)

      assert values["NAME"] == "ExVenture MUD"
    end
  end
end

defmodule Grapevine.Telnet.OptionsTest do
  use ExUnit.Case

  alias Grapevine.Telnet.Options

  doctest Options

  describe "parsing telnet options" do
    test "a string" do
      [] = Options.parse("this is a string")
    end

    test "a single option" do
      [will: :mssp] = Options.parse(<<255, 251, 70>>)
    end

    test "multiple options" do
      [will: :mssp, will: :gmcp, will: 91] = Options.parse(<<255, 251, 70, 255, 251, 201, 255, 251, 91>>)
    end

    test "parsing sub negotitation" do
      options = <<255, 250, 70, 1>> <> "name" <> <<2>> <> "grapevine" <> <<255, 240, 85>>

      [mssp: %{"name" => "grapevine"}] = Options.parse(options)
    end

    test "sub negotiation options" do
      options =
        <<255, 250, 70, 1, 78, 65, 77, 69, 2, 69, 120, 86, 101, 110, 116, 117, 114, 101, 32, 77,
          85, 68, 1, 80, 76, 65, 89, 69, 82, 83, 2, 48, 1, 85, 80, 84, 73, 77, 69, 2, 49, 53, 52,
          54, 49, 50, 56, 54, 55, 50, 255, 240, 85>>

      {sub, <<85>>} = Options.parse_sub_negotiation(options)

      assert [255, 250 | _] = sub
    end
  end
end

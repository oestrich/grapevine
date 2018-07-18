defmodule Gossip.TextTest do
  use ExUnit.Case

  alias Gossip.Text

  describe "strip mxp" do
    test "removes tags" do
      assert Text.clean("<b>Hi</b>") == "Hi"
    end
  end
end

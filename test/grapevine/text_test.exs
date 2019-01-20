defmodule Grapevine.TextTest do
  use ExUnit.Case

  alias Grapevine.Text

  describe "strip mxp" do
    test "removes tags" do
      assert Text.clean("<b>Hi</b>") == "Hi"
    end
  end
end

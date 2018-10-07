defmodule Gossip.ApplicationsTest do
  use Gossip.DataCase

  alias Gossip.Applications

  describe "generating a system level application" do
    test "successfully" do
      {:ok, application} = Applications.create_application(%{short_name: "Grapevine"})

      assert application.short_name == "Grapevine"
      assert application.client_id
      assert application.client_id
    end
  end
end

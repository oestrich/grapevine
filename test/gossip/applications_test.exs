defmodule Gossip.ApplicationsTest do
  use Gossip.DataCase

  alias Gossip.Applications

  describe "generating a system level application" do
    test "successfully" do
      {:ok, application} = Applications.create_application(%{
        name: "Grapevine",
        short_name: "Grapevine",
      })

      assert application.name == "Grapevine"
      assert application.short_name == "Grapevine"
      assert application.client_id
      assert application.client_id
    end
  end

  describe "validating the socket" do
    setup do
      %{application: create_application()}
    end

    test "when valid", %{application: application} do
      assert {:ok, _application} = Applications.validate_socket(application.client_id, application.client_secret)
    end

    test "when bad secret", %{application: application} do
      assert {:error, :invalid} = Applications.validate_socket(application.client_id, "bad")
    end

    test "when bad id", %{application: application} do
      assert {:error, :invalid} = Applications.validate_socket("bad", application.client_id)
    end
  end
end

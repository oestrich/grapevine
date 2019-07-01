defmodule GrapevineData.UserAgentsTest do
  use Grapevine.DataCase

  alias GrapevineData.UserAgents

  describe "register a user agent" do
    test "successful" do
      {:ok, user_agent} = UserAgents.register_user_agent("ExVenture 0.26.0")

      assert user_agent.version == "ExVenture 0.26.0"
    end

    test "reuses the same agent" do
      {:ok, first_user_agent} = UserAgents.register_user_agent("ExVenture 0.26.0")
      {:ok, second_user_agent} = UserAgents.register_user_agent("ExVenture 0.26.0")

      assert first_user_agent.id == second_user_agent.id
    end
  end
end

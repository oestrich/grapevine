defmodule Socket.Web.SocketHandlerTest do
  use Grapevine.DataCase

  alias Socket.RateLimit
  alias Socket.Web.SocketHandler
  alias Socket.Web.State

  describe "incoming messages are rate limited globally" do
    test "records current rate of send" do
      state = setup_state(%RateLimit{limit: 10})

      message = Jason.encode!(%{"event" => "unknown", "payload" => %{}})

      {:reply, _reply, state} = SocketHandler.websocket_handle({:text, message}, state)

      rate_limit = state.rate_limits["global"]
      assert rate_limit.current == 1
      assert rate_limit.last_sent_at
    end

    test "prevents going over your rate" do
      state = setup_state(%RateLimit{current: 10, limit: 10})
      message = Jason.encode!(%{"event" => "unknown", "payload" => %{}})

      {:reply, {:text, reply}, _state} = SocketHandler.websocket_handle({:text, message}, state)

      response = Jason.decode!(reply)
      assert response["error"] == "rate limit exceeded"
    end

    test "disconnects you if you get limited too often" do
      state = setup_state(%RateLimit{current: 10, limit: 10, total_limited: 10})
      message = Jason.encode!(%{"event" => "unknown", "payload" => %{}})

      {:reply, {:text, _reply}, _state} = SocketHandler.websocket_handle({:text, message}, state)

      assert_receive {:disconnect}
    end
  end

  def setup_state(global_rate_limit) do
    %State{
      status: "active",
      supports: ["channels"],
      channels: ["grapevine"],
      rate_limits: %{
        "global" => global_rate_limit
      }
    }
  end
end

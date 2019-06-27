defmodule GrapevineData.TelnetTest do
  use Grapevine.DataCase

  alias GrapevineData.Telnet

  describe "recording a successful response" do
    test "first time" do
      {:ok, response} = Telnet.record_mssp_response("example.com", 5555, %{})

      assert response.host == "example.com"
      assert response.port == 5555
      assert response.supports_mssp
      assert response.data == %{}
    end

    test "updates a previous response" do
      {:ok, _response} = Telnet.record_mssp_response("example.com", 5555, %{})
      {:ok, response} = Telnet.record_mssp_response("example.com", 5555, %{"name" => "game"})

      assert response.host == "example.com"
      assert response.port == 5555
      assert response.supports_mssp
      assert response.data == %{"name" => "game"}

      assert length(Repo.all(Telnet.MSSPResponse)) == 1
    end
  end

  describe "fail a game" do
    test "first time" do
      {:ok, response} = Telnet.record_no_mssp("example.com", 5555)

      assert response.host == "example.com"
      assert response.port == 5555
      refute response.supports_mssp
      assert response.data == %{}
    end

    test "updates a previous response" do
      {:ok, _response} = Telnet.record_mssp_response("example.com", 5555, %{})
      {:ok, response} = Telnet.record_no_mssp("example.com", 5555)

      assert response.host == "example.com"
      assert response.port == 5555
      refute response.supports_mssp
      assert response.data == %{}

      assert length(Repo.all(Telnet.MSSPResponse)) == 1
    end
  end
end

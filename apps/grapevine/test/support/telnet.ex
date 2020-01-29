defmodule Test.Telnet do
  @behaviour Grapevine.Telnet

  @impl true
  def check_connection(connection) do
    {:telnet, :check, connection}
  end
end

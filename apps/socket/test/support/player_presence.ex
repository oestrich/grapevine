defmodule Test.PlayerPresence do
  @moduledoc """
  Connect the local test process to the pg2 player presence group

  To not raise an error during testing
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    :ok = :pg2.create(Grapevine.PlayerPresence)
    :ok = :pg2.join(Grapevine.PlayerPresence, self())

    {:ok, %{}}
  end

  def handle_cast(_message, state), do: {:noreply, state}
end

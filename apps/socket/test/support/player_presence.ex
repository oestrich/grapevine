defmodule Test.PlayerPresence do
  @moduledoc """
  Connect the local test process to the pg2 player presence group

  To not raise an error during testing
  """

  def connect() do
    :ok = :pg2.create(Grapevine.PlayerPresence)
    :ok = :pg2.join(Grapevine.PlayerPresence, self())
  end
end

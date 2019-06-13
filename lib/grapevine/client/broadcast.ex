defmodule Grapevine.Client.Broadcast do
  @moduledoc """
  Struct for messages being broadcast on a channel
  """

  defstruct [:channel, :user, :message]
end

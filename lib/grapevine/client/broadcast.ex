defmodule Grapevine.Client.Broadcast do
  @moduledoc """
  Struct for messages being broadcast on a channel
  """

  @derive Jason.Encoder
  defstruct [:channel, :name, :message]
end

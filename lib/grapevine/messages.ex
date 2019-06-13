defmodule Grapevine.Messages do
  @moduledoc """
  Record messages posted in the chat
  """

  alias Grapevine.Messages.Message
  alias Grapevine.Repo

  @doc """
  Create a message
  """
  def create(game, channel, params) do
    %Message{}
    |> Message.create_changeset(game, channel, params)
    |> Repo.insert()
  end
end

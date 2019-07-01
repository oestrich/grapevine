defmodule GrapevineData.Messages do
  @moduledoc """
  Record messages posted in the chat
  """

  alias GrapevineData.Messages.Message
  alias GrapevineData.Repo

  @doc """
  Create a message from the socket
  """
  def record_socket(game, channel, params) do
    %Message{}
    |> Message.create_socket_changeset(game, channel, params)
    |> Repo.insert()
  end

  @doc """
  Create a message from the web chat
  """
  def record_web(channel, user, text) do
    %Message{}
    |> Message.create_web_changeset(channel, user, text)
    |> Repo.insert()
  end
end

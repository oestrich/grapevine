defmodule Grapevine.Games do
  @moduledoc """
  A wrapper for GrapevineData.Games to send emails and interact with telnet
  """

  alias GrapevineData.Games
  alias GrapevineData.Repo
  alias Grapevine.Telnet

  defdelegate delete_connection(connection), to: Games

  defdelegate edit_connection(connection), to: Games

  defdelegate get_connection(id), to: Games

  defdelegate get(id), to: Games

  defdelegate get(user, game_id), to: Games

  defdelegate user_owns_connection?(user, connection), to: Games

  @doc """
  Check a new connection and possibly check Telnet
  """
  def create_connection(game, params) do
    Games.create_connection(game, params, &maybe_check_mssp/1)
  end

  def update_connection(connection, params) do
    Games.update_connection(connection, params, &maybe_check_mssp/1)
  end

  defp maybe_check_mssp(connection) do
    case connection.type do
      "telnet" ->
        connection = Repo.preload(connection, [:game])
        Telnet.check_connection(connection)

      _ ->
        :ok
    end
  end
end

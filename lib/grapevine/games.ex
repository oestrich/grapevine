defmodule Grapevine.Games do
  @moduledoc """
  A wrapper for GrapevineData.Games to send emails and interact with telnet
  """

  alias GrapevineData.Accounts
  alias GrapevineData.Games
  alias GrapevineData.Repo
  alias Grapevine.Emails
  alias Grapevine.Mailer
  alias Grapevine.Telnet

  defdelegate connection_has_mssp(connection), to: Games

  defdelegate connection_has_no_mssp(connection), to: Games

  defdelegate connection_succeeded(connection), to: Games

  defdelegate delete_connection(connection), to: Games

  defdelegate edit_connection(connection), to: Games

  defdelegate get(id), to: Games

  defdelegate get(user, game_id), to: Games

  defdelegate get_connection(id), to: Games

  defdelegate record_metadata(game, metadata), to: Games

  defdelegate seen_on_telnet(game), to: Games

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

  @doc """
  Record a connection failed and send an alert
  """
  def connection_failed(connection) do
    {:ok, _alert} = Games.connection_failed(connection, skip_notify: true)
    {:ok, game} = get(connection.game_id)

    game
    |> Emails.connection_failed(connection)
    |> Mailer.deliver_now()

    case game.send_connection_failure_alerts do
      true ->
        {:ok, user} = Accounts.get(game.user_id)

        user
        |> Emails.connection_failed(game, connection)
        |> Mailer.deliver_now()

      false ->
        :ok
    end
  end
end

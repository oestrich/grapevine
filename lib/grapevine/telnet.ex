defmodule Grapevine.Telnet do
  @moduledoc """
  Telnet context, for finding MSSP data on a MUD
  """

  alias Grapevine.Telnet.MSSPResponse
  alias Grapevine.Repo

  @telnet Application.get_env(:grapevine, :modules)[:telnet]

  @callback check_connection(Connection.t()) :: :ok

  @doc """
  Trigger a check for connection MSSP stats
  """
  def check_connection(connection) do
    @telnet.check_connection(connection)
  end

  @doc """
  Record a successful response
  """
  def record_mssp_response(host, port, data) do
    case Repo.get_by(MSSPResponse, host: host, port: port) do
      nil ->
        %MSSPResponse{}
        |> MSSPResponse.success_changeset(host, port, data)
        |> Repo.insert()

      response ->
        response
        |> MSSPResponse.success_changeset(host, port, data)
        |> Repo.update()
    end
  end

  @doc """
  Record a failed response
  """
  def record_no_mssp(host, port) do
    case Repo.get_by(MSSPResponse, host: host, port: port) do
      nil ->
        %MSSPResponse{}
        |> MSSPResponse.fail_changeset(host, port)
        |> Repo.insert()

      response ->
        response
        |> MSSPResponse.fail_changeset(host, port)
        |> Repo.update()
    end
  end
end

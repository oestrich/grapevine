defmodule GrapevineData.Telnet.MSSPResponse do
  @moduledoc """
  Connection Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "mssp_responses" do
    field(:host, :string)
    field(:port, :integer)
    field(:supports_mssp, :boolean)
    field(:data, :map)

    timestamps()
  end

  def success_changeset(struct, host, port, data) do
    struct
    |> cast(%{host: host, port: port, data: data}, [:host, :port, :data])
    |> validate_required([:host, :port, :data])
    |> put_change(:supports_mssp, true)
  end

  def fail_changeset(struct, host, port) do
    struct
    |> cast(%{host: host, port: port}, [:host, :port])
    |> validate_required([:host, :port])
    |> put_change(:data, %{})
    |> put_change(:supports_mssp, false)
  end
end

defmodule GrapevineData.Authorizations.AccessToken do
  @moduledoc """
  Access token schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Authorizations.Authorization

  @type t :: %__MODULE__{}

  @one_hour 60 * 60

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "access_tokens" do
    field(:access_token, Ecto.UUID)
    field(:refresh_token, Ecto.UUID)
    field(:active, :boolean, default: false)
    field(:expires_in, :integer, default: @one_hour)

    belongs_to(:authorization, Authorization)

    timestamps()
  end

  def create_changeset(struct) do
    struct
    |> change()
    |> put_change(:active, true)
    |> put_change(:access_token, UUID.uuid4())
    |> put_change(:refresh_token, UUID.uuid4())
  end
end

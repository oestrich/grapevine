defmodule GrapevineData.Alerts.Alert do
  @moduledoc """
  Alert Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "alerts" do
    field(:title, :string)
    field(:body, :string)

    timestamps()
  end

  def changeset(struct, title, body) do
    struct
    |> cast(%{title: title, body: body}, [:title, :body])
    |> validate_required([:title, :body])
  end
end

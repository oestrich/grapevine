defmodule GrapevineData.Schema do
  @moduledoc """
  Helper for setting up Ecto
  """

  import Ecto.Changeset

  def ensure(changeset, field, default) do
    case get_field(changeset, field) do
      nil ->
        put_change(changeset, field, default)

      _ ->
        changeset
    end
  end
end

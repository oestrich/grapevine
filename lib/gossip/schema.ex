defmodule Gossip.Schema do
  @moduledoc """
  Helper for setting up Ecto
  """

  import Ecto.Changeset

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Gossip.Schema

      alias Gossip.Repo

      @type t :: %__MODULE__{}
    end
  end

  def ensure(changeset, field, default) do
    case get_field(changeset, field) do
      nil ->
        put_change(changeset, field, default)

      _ ->
        changeset
    end
  end
end

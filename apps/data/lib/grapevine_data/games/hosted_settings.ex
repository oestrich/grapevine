defmodule GrapevineData.Games.HostedSettings do
  @moduledoc """
  Client settings Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "hosted_settings" do
    field(:welcome_text, :string)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    cast(struct, params, [:welcome_text])
  end
end

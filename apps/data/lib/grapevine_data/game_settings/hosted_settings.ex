defmodule GrapevineData.GameSettings.HostedSettings do
  @moduledoc """
  Client settings Schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias GrapevineData.Games.Game

  @type t :: %__MODULE__{}

  schema "hosted_settings" do
    field(:welcome_text, :string)
    field(:display_description_on_homepage, :boolean, default: true)

    belongs_to(:game, Game)

    timestamps()
  end

  def changeset(struct, params) do
    cast(struct, params, [:display_description_on_homepage, :welcome_text])
  end
end

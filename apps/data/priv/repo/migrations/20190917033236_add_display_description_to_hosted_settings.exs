defmodule GrapevineData.Repo.Migrations.AddDisplayDescriptionToHostedSettings do
  use Ecto.Migration

  def change do
    alter table(:hosted_settings) do
      add(:display_description_on_homepage, :boolean, default: true, null: false)
    end
  end
end

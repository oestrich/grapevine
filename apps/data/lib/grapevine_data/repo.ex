defmodule GrapevineData.Repo do
  @moduledoc """
  The socket repo
  """

  use Ecto.Repo, otp_app: :grapevine_data, adapter: Ecto.Adapters.Postgres
end

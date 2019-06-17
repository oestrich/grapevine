defmodule Data.Repo do
  @moduledoc """
  The socket repo
  """

  use Ecto.Repo, otp_app: :grapevine, adapter: Ecto.Adapters.Postgres
end

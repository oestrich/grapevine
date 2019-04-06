defmodule Grapevine.Contact do
  @moduledoc """
  Contact context
  """

  alias Grapevine.Emails
  alias Grapevine.Mailer

  def send(params) do
    with {:ok, name} <- Map.fetch(params, "name"),
         {:ok, email} <- Map.fetch(params, "email"),
         {:ok, body} <- Map.fetch(params, "body") do
      email = Emails.contacted(name, email, body)
      Mailer.deliver_later(email)
    end
  end
end

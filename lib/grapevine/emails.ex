defmodule Grapevine.Emails do
  @moduledoc """
  Generate emails to send out
  """

  use Bamboo.Phoenix, view: Web.EmailView

  @doc """
  Send a password reset email
  """
  def password_reset(user) do
    base_email()
    |> to(user.email)
    |> subject("Password reset for Grapevine")
    |> render("password-reset.html", user: user)
  end

  def base_email() do
    new_email()
    |> from("no-reply@grapevine.haus")
  end
end

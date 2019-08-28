defmodule Grapevine.Emails do
  @moduledoc """
  Generate emails to send out
  """

  use Bamboo.Phoenix, view: Web.EmailView

  @doc """
  Send a email verification email
  """
  def verify_email(user) do
    base_email()
    |> to(user.email)
    |> subject("Grapevine - Please verify your email address")
    |> render("verify-email.html", user: user)
  end

  @doc """
  Send a password reset email
  """
  def password_reset(user) do
    base_email()
    |> to(user.email)
    |> subject("Password reset for Grapevine")
    |> render("password-reset.html", user: user)
  end

  def contacted(name, email, body) do
    base_email()
    |> to(alert_to())
    |> subject("Graepvine - New contact submission")
    |> assign(:name, name)
    |> assign(:email, email)
    |> assign(:body, body)
    |> render("contacted.html")
  end

  def new_alert(alert) do
    base_email()
    |> to(alert_to())
    |> subject("Grapevine - New alert - #{alert.title}")
    |> text_body(alert.body)
  end

  def connection_failed(user, game, connection) do
    base_email()
    |> to(user.email)
    |> subject("Grapevine - Connection failed to #{game.name}")
    |> assign(:game, game)
    |> assign(:connection, connection)
    |> render("connection-failed.html")
  end

  def connection_failed(game, connection) do
    base_email()
    |> to(alert_to())
    |> subject("Grapevine - Connection failed to #{game.name}")
    |> assign(:game, game)
    |> assign(:connection, connection)
    |> render("connection-failed.html")
  end

  def new_game_registered(game) do
    base_email()
    |> to(alert_to())
    |> subject("Grapevine - New game registered - #{game.name}")
    |> assign(:game, game)
    |> render("new-game-registered.html")
  end

  def base_email() do
    new_email()
    |> from("no-reply@mg.grapevine.haus")
  end

  defp alert_to() do
    Application.get_env(:grapevine, Grapevine.Mailer)[:alert_to]
  end
end

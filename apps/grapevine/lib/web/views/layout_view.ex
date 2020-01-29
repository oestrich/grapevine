defmodule Web.LayoutView do
  use Web, :view

  alias GrapevineData.Accounts
  alias Web.HostedRouter.Helpers, as: HostedRoutes
  alias Web.Hosted
  alias Web.RecaptchaView

  @config Application.get_env(:grapevine, :web)[:url]
  @decanter_enabled Application.get_env(:grapevine, :decanter)[:enabled]

  def user_token(%{assigns: %{user_token: token}}), do: token
  def user_token(_), do: ""

  def session_token(%{assigns: %{session_token: token}}), do: token
  def session_token(_), do: ""

  def analytics_configured?() do
    analytics_id() != nil
  end

  def analytics_id() do
    Application.get_env(:grapevine, :web)[:analytics_id]
  end

  def grapevine_url() do
    uri = %URI{scheme: @config[:scheme], host: @config[:host], port: @config[:port]}
    Routes.page_url(uri, :index)
  end

  def decanter_enabled?(), do: @decanter_enabled

  @doc """
  Show the verification alert if the user hasn't verified and is older than a day old.
  """
  def show_verification_push?(nil), do: false

  def show_verification_push?(user) do
    !Accounts.email_verified?(user) && Timex.diff(Timex.now(), user.inserted_at, :days) >= 1
  end
end

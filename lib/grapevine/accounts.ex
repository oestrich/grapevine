defmodule Grapevine.Accounts do
  @moduledoc """
  A wrapper for GrapevineData.Accounts to send emails
  """

  alias GrapevineData.Accounts

  alias Grapevine.Emails
  alias Grapevine.Mailer

  defdelegate change_password(user, current_password, params), to: Accounts

  defdelegate edit(user), to: Accounts

  defdelegate new(), to: Accounts

  defdelegate reset_password(token, params), to: Accounts

  defdelegate verify_email(token), to: Accounts

  @doc """
  Register an account and send a verification email
  """
  def register(params) do
    Accounts.register(params, &deliver_verify_email/1)
  end

  defp deliver_verify_email(user) do
    :telemetry.execute([:grapevine, :accounts, :email, :send_verify], %{count: 1})

    user
    |> Emails.verify_email()
    |> Mailer.deliver_later()
  end

  @doc """
  Update the user and possibly send a new verification email
  """
  def update(user, params) do
    Accounts.update(user, params, &maybe_send_new_verification/2)
  end

  defp maybe_send_new_verification({:ok, user}, original_user) do
    case user.email == original_user.email do
      true ->
        {:ok, user}

      false ->
        deliver_verify_email(user)
        {:ok, user}
    end
  end

  defp maybe_send_new_verification(result, _original_user), do: result

  @doc """
  Start password reset
  """
  @spec start_password_reset(String.t()) :: :ok
  def start_password_reset(email) do
    Accounts.start_password_reset(email, fn user ->
      user
      |> Emails.password_reset()
      |> Mailer.deliver_now()
    end)
  end
end

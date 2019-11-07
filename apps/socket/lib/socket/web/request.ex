defmodule Socket.Web.Request do
  @moduledoc """
  Handle the "request parsing" part of a new message

  Checking for the correct supports, etc, before processing the event
  """

  def check_support_flag(state, flag) do
    case flag in state.supports do
      true ->
        {:ok, :support_present}

      false ->
        {:error, :support_missing}
    end
  end
end

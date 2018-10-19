defmodule Web.Socket.Response do
  @moduledoc """
  Token for responding to a request frame
  """

  defstruct [:value, :event, :flag]

  @doc """
  Wrap an internal response value from a module
  """
  def wrap(value, event, flag) do
    %__MODULE__{value: value, event: event, flag: flag}
  end

  @doc """
  Respond to a request frame

  Response must be wrapped by `wrap/3`
  """
  def respond_to(response, state) do
    case response.value do
      {:ok, :skip, state} ->
        {:ok, :skip, state}

      {:ok, response, state} ->
        {:ok, response, state}

      {:ok, state} ->
        response =
          response.event
          |> maybe_respond(state)
          |> succeed_response()

        {:ok, response, state}

      {:error, :missing_support} ->
        response =
          response.event
          |> maybe_respond(state)
          |> fail_response(~s(missing support for "#{response.flag}"))

        {:ok, response, state}

      {:error, error} ->
        response =
          response.event
          |> maybe_respond(state)
          |> fail_response(error)

        {:ok, response, state}

      :error ->
        response =
          response.event
          |> maybe_respond(state)
          |> fail_response("an error occurred, try again")

        {:ok, response, state}

      {:disconnect, response, state} ->
        {:disconnect, response, state}
    end
  end

  defp maybe_respond(event, state) do
    case Map.has_key?(event, "ref") || state.debug do
      true ->
        Map.take(event, ["event", "ref"])

      false ->
        :skip
    end
  end

  defp succeed_response(:skip), do: :skip

  defp succeed_response(response) do
    Map.put(response, "status", "success")
  end

  defp fail_response(:skip, _), do: :skip

  defp fail_response(response, reason) do
    response
    |> Map.put("status", "failure")
    |> Map.put("error", reason)
  end
end

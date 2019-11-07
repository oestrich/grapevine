defmodule Socket.Web.Response do
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
  def respond_to(%{value: {:ok, :skip, state}}, _state), do: {:ok, :skip, state}

  def respond_to(%{value: {:ok, response, state}}, _state), do: {:ok, response, state}

  def respond_to(response = %{value: {:ok, state}}, _state) do
    response =
      response.event
      |> maybe_respond(state)
      |> succeed_response()

    {:ok, response, state}
  end

  def respond_to(response = %{value: {:error, :support_missing}}, state) do
    response =
      response.event
      |> maybe_respond(state)
      |> fail_response(~s(missing support for "#{response.flag}"))

    {:ok, response, state}
  end

  def respond_to(response = %{value: {:error, error, state}}, _state) do
    response =
      response.event
      |> maybe_respond(state)
      |> fail_response(error)

    {:ok, response, state}
  end

  def respond_to(response = %{value: {:error, error}}, state) do
    response =
      response.event
      |> maybe_respond(state)
      |> fail_response(error)

    {:ok, response, state}
  end

  def respond_to(response = %{value: :error}, state) do
    response =
      response.event
      |> maybe_respond(state)
      |> fail_response("an error occurred, try again")

    {:ok, response, state}
  end

  def respond_to(%{value: {:disconnect, :limit_exceeded, rate_limit}}, state) do
    :telemetry.execute([:grapevine, :events, :rate_limited], rate_limit)

    response = %{
      "event" => "authenticate",
      "status" => "failure",
      "error" => "disconnected due to rate limit abuse"
    }

    {:disconnect, response, state}
  end

  def respond_to(%{value: {:disconnect, response, state}}, _state),
    do: {:disconnect, response, state}

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

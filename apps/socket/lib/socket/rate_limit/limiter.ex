defmodule Socket.RateLimit.Limiter do
  @moduledoc """
  Handles common rate limiting functionality for the socket
  """

  alias Socket.RateLimit

  @doc """
  Check a specific rate limit
  """
  def check_rate_limit(state, rate_limit_name) do
    rate_limit = state.rate_limits[rate_limit_name]

    case RateLimit.increase(rate_limit) do
      {:ok, rate_limit} ->
        rate_limits = Map.put(state.rate_limits, rate_limit_name, rate_limit)
        {:ok, %{state | rate_limits: rate_limits}}

      {:error, :max_limit_exceeded, rate_limit} ->
        {:disconnect, :limit_exceeded, rate_limit}

      {:error, :limit_exceeded, rate_limit} ->
        {:error, :limit_exceeded, rate_limit}
    end
  end

  def update_rate_limit(state, rate_limit_name, rate_limit) do
    rate_limits = Map.put(state.rate_limits, rate_limit_name, rate_limit)
    %{state | rate_limits: rate_limits}
  end
end

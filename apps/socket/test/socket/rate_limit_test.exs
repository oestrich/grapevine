defmodule Socket.RateLimitTest do
  use ExUnit.Case

  alias Socket.RateLimit

  doctest Socket.RateLimit

  describe "increase current count" do
    test "under the limit" do
      rate_limit = %RateLimit{current: 0}

      {:ok, rate_limit} = RateLimit.increase(rate_limit)

      assert rate_limit.current == 1
    end

    test "saves the timestamp" do
      now = Timex.now()

      rate_limit = %RateLimit{last_sent_at: nil}

      {:ok, rate_limit} = RateLimit.increase(rate_limit, now)

      assert rate_limit.last_sent_at == now
    end

    test "the bucket leaks" do
      now = Timex.now()
      two_seconds_ago = Timex.shift(now, seconds: -2)

      rate_limit = %RateLimit{current: 10, last_sent_at: two_seconds_ago, rate_per_second: 3}

      {:ok, rate_limit} = RateLimit.increase(rate_limit, now)

      # 10 (current) - 2 seconds * 3 per second + 1 (increase)
      assert rate_limit.current == 5
    end

    test "the bucket leaks but stays above 0" do
      now = Timex.now()
      ten_seconds_ago = Timex.shift(now, seconds: -10)

      rate_limit = %RateLimit{current: 10, last_sent_at: ten_seconds_ago, rate_per_second: 3}

      {:ok, rate_limit} = RateLimit.increase(rate_limit, now)

      # 10 (current) - 10 seconds * 3 per second + 1 (increase)
      assert rate_limit.current == 1
    end

    test "at the limit" do
      now = Timex.now()

      rate_limit = %RateLimit{
        current: 10,
        limit: 10,
        last_sent_at: now,
        rate_per_second: 1
      }

      {:error, :limit_exceeded, rate_limit} = RateLimit.increase(rate_limit, now)

      assert rate_limit.total_limited == 1
    end
  end
end

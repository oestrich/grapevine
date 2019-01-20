defmodule Grapevine.SentryFilter do
  @moduledoc false

  @behaviour Sentry.EventFilter

  def exclude_exception?(%Phoenix.Router.NoRouteError{}, :plug), do: true
  def exclude_exception?(_exception, _source), do: false
end

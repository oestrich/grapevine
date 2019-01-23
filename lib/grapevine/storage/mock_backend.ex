defmodule Grapevine.Storage.MockBackend do
  @moduledoc """
  A no-op storage backend for testing
  """

  @behaviour Grapevine.Storage

  @impl true
  def download(_key) do
    {:ok, "test/fixtures/cover.png"}
  end

  @impl true
  def upload(_file, _key), do: :ok

  @impl true
  def url(key), do: key
end

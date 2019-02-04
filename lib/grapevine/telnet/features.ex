defmodule Grapevine.Telnet.Features do
  @moduledoc """
  Struct and functions for tracking Telnet option statuses
  """

  defstruct [gmcp: false, modules: [], message_cache: %{}]

  @doc """
  Enable GMCP on the telnet state
  """
  def enable_gmcp(state) do
    features = Map.put(state.features, :gmcp, true)
    Map.put(state, :features, features)
  end

  @doc """
  Add GMCP modules to the feature set
  """
  def modules(state, modules) do
    modules = Map.get(state.features, :modules) ++ modules
    modules = Enum.uniq(modules)
    features = Map.put(state.features, :modules, modules)
    Map.put(state, :features, features)
  end

  @doc """
  Check if a GMCP message is enabled and can be forwarded
  """
  def message_enabled?(%{features: features}, message) do
    [_message | module] = Enum.reverse(String.split(message, "."))
    module = Enum.join(Enum.reverse(module), ".")
    module in features.modules || module == "Core"
  end

  @doc """
  Cache the message for repeating to a reloaded browser
  """
  def cache_message(state, message, data) do
    cache = Map.put(state.features.message_cache, message, data)
    features = Map.put(state.features, :message_cache, cache)
    Map.put(state, :features, features)
  end
end

defmodule GrapevineTelnet.ClientSupervisor do
  @moduledoc """
  A supervisor to look over all web client processes
  """

  use DynamicSupervisor

  alias GrapevineTelnet.Client

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, [], opts)
  end

  def start_client(callback_module, opts) do
    spec = {Client, [module: callback_module] ++ opts}
    DynamicSupervisor.start_child({:global, __MODULE__}, spec)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

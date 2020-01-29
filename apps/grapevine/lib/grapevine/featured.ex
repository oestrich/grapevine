defmodule Grapevine.Featured do
  @moduledoc """
  Updates the home page with featured games nightly

  Selection includes:
  - Games sorted by average player count, top 6 taken
  - Games that are connected to the chat network, random 3
  - Any game not included above, a random 3

  Soon to include:
  - Games that use the web client
  """

  use GenServer

  alias Grapevine.Featured.Implementation

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, %{}, {:continue, :schedule_next_run}}
  end

  def handle_continue(:schedule_next_run, state) do
    next_run_delay = Implementation.calculate_next_cycle_delay(Timex.now())
    Process.send_after(self(), :select_featured, next_run_delay)
    {:noreply, state}
  end

  def handle_info(:select_featured, state) do
    Implementation.select_featured()
    {:noreply, state, {:continue, :schedule_next_run}}
  end
end

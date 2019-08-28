defmodule Grapevine.Notifications do
  @moduledoc """
  Notifications context
  """

  use GenServer

  alias Grapevine.Notifications.Implementation

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_) do
    :ok = :pg2.create(__MODULE__)
    :ok = :pg2.join(__MODULE__, self())

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:new_alert, alert, opts}, state) do
    Implementation.new_alert(alert, opts)
    {:noreply, state}
  end

  def handle_cast({:new_game, game}, state) do
    Implementation.new_game(game)
    {:noreply, state}
  end

  defmodule Implementation do
    @moduledoc false

    alias Grapevine.Emails
    alias Grapevine.Mailer

    def new_alert(alert, opts) do
      case Keyword.get(opts, :skip_notify, false) do
        true ->
          :ok

        false ->
          send_alert(alert)
      end
    end

    defp send_alert(alert) do
      alert
      |> Emails.new_alert()
      |> Mailer.deliver_now()
    end

    def new_game(game) do
      :telemetry.execute([:grapevine, :games, :create], %{count: 1}, %{id: game.id})

      game
      |> Emails.new_game_registered()
      |> Mailer.deliver_now()
    end
  end
end

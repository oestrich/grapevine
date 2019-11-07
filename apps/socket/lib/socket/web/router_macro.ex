defmodule Socket.Web.RouterMacro do
  @moduledoc """
  Generate the router receive functions via a macro
  """

  @doc """
  Macro to generate the receive functions

      receives(Socket.Web) do
        module(Players, "players") do
          event("players/status", :request_status)
        end
      end
  """
  defmacro receives(module, opts) do
    out = parse_modules(module, opts[:do])

    quote do
      alias Socket.Web.Request
      alias Socket.Web.Response

      @doc """
      Receive a new event from the socket
      """
      unquote(out)
    end
  end

  def parse_modules({:__aliases__, _, top_module}, {:__block__, [], modules}) do
    Enum.map(modules, fn module ->
      parse_module(top_module, module)
    end)
  end

  def parse_module(top_module, {:module, _, args}) do
    [module, flag, args] = args
    module = {:__aliases__, elem(module, 1), top_module ++ elem(module, 2)}

    parse_events(module, flag, args[:do])
  end

  def parse_module(_top_module, _) do
    raise "Unknown function encountered"
  end

  def parse_events(module, flag, {:__block__, _, events}) do
    Enum.map(events, fn event ->
      parse_event(module, flag, event)
    end)
  end

  # there isn't a wrapping do block for single events
  def parse_events(module, flag, {:event, opts, event}) do
    parse_event(module, flag, {:event, opts, event})
  end

  def parse_event(module, flag, {:event, _, [event, fun]}) do
    quote do
      def receive(state = %{status: "active"}, event = %{"event" => unquote(event)}) do
        with {:ok, :support_present} <- Request.check_support_flag(state, unquote(flag)) do
          state
          |> unquote(module).unquote(fun)(event)
          |> Response.wrap(event, unquote(flag))
          |> Response.respond_to(state)
        else
          {:error, :support_missing} ->
            {:error, :support_missing}
            |> Response.wrap(event, unquote(flag))
            |> Response.respond_to(state)
        end
      end
    end
  end

  def parse_event(_module, _flag, _) do
    raise "Unknown function encountered"
  end
end

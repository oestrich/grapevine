defmodule Web.Admin.ChannelView do
  use Web, :view

  alias Web.Admin.DashboardView
  alias Web.Admin.MessageView
  alias Web.TimeView

  def render("show.json", %{channel: channel, messages: messages}) do
    channel
    |> show(messages)
    |> Representer.transform("json")
  end

  def render("channel.json", %{channel: channel}) do
    Map.take(channel, [:name, :description])
  end

  defp show(channel, messages) do
    messages = render_many(messages, MessageView, "show.json")

    %Representer.Item{
      data: render("channel.json", %{channel: channel}),
      embedded: %{messages: messages}
    }
  end
end

defmodule Web.Admin.MessageView do
  use Web, :view

  def render("show.json", %{message: message}) do
    message
    |> show()
    |> Representer.transform("json")
  end

  def render("message.json", %{message: message}) do
    Map.take(message, [:id, :inserted_at, :name, :game, :text])
  end

  defp show(message) do
    %Representer.Item{
      data: render("message.json", %{message: message})
    }
  end
end

defmodule Socket.Text do
  @moduledoc """
  Incoming text modifications

  Strip MXP from the response.
  """

  @doc """
  Clean incoming text for broadcast
  """
  @spec clean(String.t()) :: String.t()
  def clean(string) do
    string |> String.replace(~r/<[^>]*>/, "")
  end
end

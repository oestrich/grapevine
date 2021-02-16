defmodule Grapevine.Recaptcha do
  @moduledoc """
  Verify if a recaptcha token was valid
  """

  require Logger

  def valid?(params) do
    config = Application.get_env(:grapevine, :recaptcha)

    case config[:enabled] do
      true ->
        valid_token?(config, Map.get(params, "g-recaptcha-response"))

      false ->
        Keyword.get(config, :disabled_response, true)
    end
  end

  def valid_token?(_config, nil), do: false

  def valid_token?(_config, ""), do: false

  def valid_token?(config, token) do
    url = "https://www.google.com/recaptcha/api/siteverify"
    headers = [{"content-type", "application/x-www-form-urlencoded"}]
    body = URI.encode_query(%{secret: config[:secret_key], response: token})

    {:ok, response} = Mojito.post(url, headers, body)

    case response.status_code == 200 do
      true ->
        valid_response?(response.body)

      false ->
        false
    end
  end

  def valid_response?(body) do
    {:ok, body} = Jason.decode(body)
    Logger.debug(inspect(body))
    body["success"]
  end
end

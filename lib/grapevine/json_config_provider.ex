defmodule Grapevine.JSONConfigProvider do
  @moduledoc """
  Config provider for production

  Loads runtime configuration for the application
  """

  @behaviour Config.Provider

  # Let's pass the path to the JSON file as config
  def init(path) when is_binary(path), do: path

  def load(config, path) do
    # We need to start any app we may depend on.
    {:ok, _} = Application.ensure_all_started(:jason)

    json = path |> File.read!() |> Jason.decode!()

    Config.Reader.merge(
      config,
      grapevine: [
        {:errors, [report: json["report_errors"]]},
        {GrapevineData.Repo, [url: json["database_url"]]},
        {Web.Endpoint, [secret_key_base: json["web_secret_key_base"]]}
      ],
      sentry: [dsn: json["sentry_dsn"]]
    )
  end
end

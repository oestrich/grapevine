defmodule Grapevine.ConfigProvider do
  @moduledoc """
  Config provider for production

  Loads runtime configuration for the application
  """

  @behaviour Config.Provider

  # Let's pass the path to the JSON file as config
  @impl true
  def init(path) when is_binary(path), do: path

  @impl true
  def load(config, path) do
    Config.Reader.merge(config, Config.Reader.read!(path))
  end

  def load_json(config, path) do
    # We need to start any app we may depend on.
    {:ok, _} = Application.ensure_all_started(:jason)

    json = path |> File.read!() |> Jason.decode!()

    Config.Reader.merge(
      config,
      ex_aws: [
        {:access_key_id, json["exaws_key_id"]},
        {:secret_access_key, json["exaws_secret_access_key"]}
      ],
      grapevine: [
        {:errors, [report: json["report_errors"]]},
        {:socket, [tls: json["socket_tls"]]},
        {:topologies, topologies(json)},
        {:web, [analytics_id: json["web_analytics_id"]]},
        {Grapevine.Mailer,
         [
           alert_to: json["email_alert_to"],
           username: json["email_smtp_username"],
           password: ["email_smpt_password"]
         ]},
        {Web.Endpoint, [secret_key_base: json["web_secret_key_base"]]}
      ],
      grapevine_data: [
        {GrapevineData.Repo, [url: json["database_url"]]}
      ],
      sentry: [
        {:dsn, json["sentry_dsn"]}
      ],
      stein: [
        {:bucket, json["stein_bucket"]}
      ],
      timber: [
        {:api_key, json["timber_api_key"]}
      ]
    )
  end

  defp topologies(json) do
    hosts = Enum.map(json["cluster_topology_hosts"], &String.to_atom/1)

    [
      local: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: hosts]
      ]
    ]
  end
end

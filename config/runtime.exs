
import Config

if config_env() == :prod do
  config :ex_aws, :s3,
    scheme: "#{System.get_env("S3_URL_SCHEME")}://",
    host: System.get_env("S3_HOST"),
    port: System.get_env("S3_PORT"),
    region: System.get_env("S3_REGION"),
    access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY")

  if System.get_env("CLUSTERING_STRATEGY") == "gossip" do
    config :libcluster, topologies: [
      gossip: [strategy: Elixir.Cluster.Strategy.Gossip]
    ]
  end

  if System.get_env("CLUSTERING_STRATEGY") == "k8s" do
    config :libcluster, topologies: [
      k8s: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          application_name: "aasa-assetlinks",
          service: System.get_env("CLUSTERING_STRATEGY_K8S_HEADLESS_SERVICE_NAME", "aasa-assetlinks")
        ]
      ]
    ]
  end
end

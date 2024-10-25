import Config

config :libcluster, topologies: []

config :ex_aws,
  http_client: AasaAssetlinksServer.AwsHttpClient

import_config "#{config_env()}.exs"

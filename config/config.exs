import Config

config :libcluster, topologies: []

import_config "#{config_env()}.exs"

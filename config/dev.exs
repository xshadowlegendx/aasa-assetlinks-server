
import Config

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 3900,
  region: "garage",
  access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY")

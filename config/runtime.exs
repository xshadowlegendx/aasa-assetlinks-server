
import Config

if config_env() == :prod do
  config :ex_aws, :s3,
    scheme: "#{System.get_env("S3_URL_SCHEME")}://",
    host: System.get_env("S3_HOST"),
    port: System.get_env("S3_PORT"),
    region: System.get_env("S3_REGION"),
    access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY")
end

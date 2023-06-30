require 'pg'
require_relative 'config'

# Connection test
begin
  # conn = PG.connect(CONN_INFO)
  # Connection settings
  db_config = Config::DB_CONFIG
  # host = 'ep-hidden-salad-492177.ap-southeast-1.aws.neon.tech'
  # port = 5432
  # database = 'data_pipeline'
  # user = 'jasonroberto38'
  # password = 'fULOsTQa54tp'

  # Establish a connection
  # conn = PG.connect(host: host, port: port, dbname: database, user: user, password: password)
  conn = PG.connect(db_config)
  puts 'Connection successful'

rescue PG::Error => e
  puts "Connection failed: #{e.message}"
ensure
  conn.close
end

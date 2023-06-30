require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("alter table stock_prices_intraday drop column if exists average_price,
drop column if exists created_at,
drop column if exists year_month;")

#add average_price column for intraday
conn.exec("alter table stock_prices_intraday ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_intraday set average_price= ROUND((open + high + low + close) / 4,3);")

conn.exec("ALTER TABLE stock_prices_intraday ADD COLUMN year_month VARCHAR(10);")
conn.exec("UPDATE stock_prices_intraday SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")


conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_intraday ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)

# Execute an SQL command to add the computed column
conn.exec("alter table stock_prices_intraday drop column if exists average_price")
conn.exec("alter table stock_prices_daily drop column if exists average_price")
conn.exec("alter table stock_prices_weekly drop column if exists average_price")
conn.exec("alter table stock_prices_monthly drop column if exists average_price")

conn.exec("alter table stock_prices_intraday ADD COLUMN average_price numeric generated always AS (ROUND((open + high + low + close) / 4,2)) stored;")
conn.exec("alter table stock_prices_daily ADD COLUMN average_price numeric generated always AS (ROUND((open + high + low + close) / 4,2)) stored;")
conn.exec("alter table stock_prices_weekly ADD COLUMN average_price numeric generated always AS (ROUND((open + high + low + close) / 4,2)) stored;")
conn.exec("alter table stock_prices_monthly ADD COLUMN average_price numeric generated always AS (ROUND((open + high + low + close) / 4,2)) stored;")

# Close the database connection
conn.close
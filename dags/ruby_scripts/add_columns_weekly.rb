require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("alter table stock_prices_weekly drop column if exists average_price;")

#drop columns for stock_prices_weekly
conn.exec("alter table stock_prices_weekly 
drop column if exists previous_value cascade, 
drop column if exists percent_change cascade,
drop column if exists change cascade,
drop column if exists created_at,
drop column if exists year_month;")

#add average_price column for weekly
conn.exec("alter table stock_prices_weekly ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_weekly set average_price= ROUND((open + high + low + close) / 4,3);")

# #adding previous_value column to weekly
conn.exec("ALTER TABLE stock_prices_weekly ADD COLUMN previous_value numeric;")

# #inserting data to previous_value column weekly
conn.exec("UPDATE stock_prices_weekly
SET previous_value = subquery.previous_value
FROM (
    SELECT
        symbol,
        timestamp,
        LAG(close) OVER (PARTITION BY symbol ORDER BY symbol, timestamp) AS previous_value
    FROM stock_prices_weekly
) AS subquery
WHERE stock_prices_weekly.symbol = subquery.symbol AND stock_prices_weekly.timestamp = subquery.timestamp;")

# # add computed columns for change & %_change weekly
conn.exec("alter table stock_prices_weekly ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("alter table stock_prices_weekly ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")

conn.exec("ALTER TABLE stock_prices_weekly ADD COLUMN year_month VARCHAR(10);")
conn.exec("UPDATE stock_prices_weekly SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")




conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_weekly ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
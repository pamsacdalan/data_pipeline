require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("alter table stock_prices_daily drop column if exists average_price;")

#drop columns for stock_prices_daily
conn.exec("alter table stock_prices_daily 
drop column if exists previous_value cascade, 
drop column if exists percent_change cascade,
drop column if exists change cascade,
drop column if exists created_at,
drop column if exists first_day_close,
drop column if exists ytd,
drop column if exists year_month;")

#add average_price column for daily
conn.exec("alter table stock_prices_daily ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_daily set average_price= ROUND((open + high + low + close) / 4,3);")

#adding previous_value column to daily
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN previous_value numeric;")

# #inserting data to previous_value column daily
conn.exec("UPDATE stock_prices_daily
SET previous_value = subquery.previous_value
FROM (
    SELECT
        symbol,
        timestamp,
        LAG(close) OVER (PARTITION BY symbol ORDER BY symbol, timestamp) AS previous_value
    FROM stock_prices_daily
) AS subquery
WHERE stock_prices_daily.symbol = subquery.symbol AND stock_prices_daily.timestamp = subquery.timestamp;")

# add computed columns for change & %_change
conn.exec("alter table stock_prices_daily ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("alter table stock_prices_daily ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")

##
conn.exec("ALTER TABLE stock_prices_daily ADD first_day_close numeric;")
conn.exec("UPDATE stock_prices_daily AS t1
SET first_day_close = t2.close
FROM (
  SELECT symbol, close
  FROM stock_prices_daily AS t3
  WHERE t3.timestamp = (
    SELECT MIN(timestamp)
    FROM stock_prices_daily AS t4
    WHERE t3.symbol = t4.symbol
  )
  GROUP BY symbol, close
) AS t2 WHERE t1.symbol = t2.symbol;")

conn.exec("ALTER TABLE stock_prices_daily ADD YTD numeric;")
conn.exec("update stock_prices_daily set ytd = round(((close-first_day_close)/first_day_close)*100,3);")

conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN year_month VARCHAR(10);")
conn.exec("UPDATE stock_prices_daily SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")





conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
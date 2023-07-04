require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("ALTER TABLE stock_prices_daily DROP COLUMN IF EXISTS average_price;")

#drop columns for stock_prices_daily
conn.exec("ALTER TABLE stock_prices_daily 
DROP COLUMN IF EXISTS previous_value cascade, 
DROP COLUMN IF EXISTS percent_change cascade,
DROP COLUMN IF EXISTS change cascade,
DROP COLUMN IF EXISTS created_at,
DROP COLUMN IF EXISTS first_day_close,
DROP COLUMN IF EXISTS ytd,
DROP COLUMN IF EXISTS year_month,
DROP COLUMN IF EXISTS company_name,
DROP COLUMN IF EXISTS timestamp_date,
DROP COLUMN IF EXISTS timestamp_year,
DROP COLUMN IF EXISTS timestamp_month,
DROP COLUMN IF EXISTS timestamp_day;")

#add average_price column for daily
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN average_price numeric;")
conn.exec("UPDATE stock_prices_daily SET average_price= ROUND((open + high + low + close) / 4,3);")

#adding previous_value column to daily
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN previous_value numeric;")

#inserting data to previous_value column daily
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
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")

# add column for first_day_close (used for ytd computation)
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

#add column for ytd
conn.exec("ALTER TABLE stock_prices_daily ADD YTD numeric;")
conn.exec("UPDATE stock_prices_daily SET ytd = round(((close-first_day_close)/first_day_close)*100,3);")

#add column for year_month ex."2023-Apr"
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN year_month VARCHAR(10);")
conn.exec("UPDATE stock_prices_daily SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add column for timestamp_date
conn.exec("ALTER TABLE stock_prices_daily ADD timestamp_date DATE;")
conn.exec("UPDATE stock_prices_daily SET timestamp_date = CAST(timestamp AS DATE);")

#add column for company name
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN company_name TEXT;")
conn.exec("UPDATE stock_prices_daily
SET company_name = 
  CASE
  WHEN symbol = 'AAPL' THEN 'Apple Inc.'
  WHEN symbol = 'MSFT' THEN 'Microsoft Corporation'
	WHEN symbol = 'GOOGL' THEN 'Alphabet Inc. (Google)'
	WHEN symbol = 'AMZN' THEN 'Amazon.com Inc.'
	WHEN symbol = 'TSLA' THEN 'Tesla Inc.'
	WHEN symbol = 'AAA' THEN 'Asia Amalgamated Holdings Corp.'
	WHEN symbol = 'SM' THEN 'SM Investments Corporation'
	WHEN symbol = 'TEL' THEN 'PLDT, Inc.'
	WHEN symbol = 'GLO' THEN 'Globe Telecom, Inc.'
	WHEN symbol = 'UBP' THEN 'Union Bank of the Philippines'
  ELSE ''
  END;")


#add columns for timestamp year, month, day
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN timestamp_day text, ADD COLUMN timestamp_month text, ADD COLUMN timestamp_year text;")
conn.exec("UPDATE stock_prices_daily
SET timestamp_day = EXTRACT(DAY FROM timestamp),
timestamp_month = to_char(timestamp, 'Month'),
timestamp_year = to_char(timestamp, 'YYYY');")





#add column for created_at (date_time of insertion to db)
conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_daily ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
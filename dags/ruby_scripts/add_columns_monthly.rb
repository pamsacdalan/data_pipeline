require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("ALTER TABLE stock_prices_monthly DROP COLUMN IF EXISTS average_price;")

#drop columns for stock_prices_monthly
conn.exec("ALTER TABLE stock_prices_monthly 
DROP COLUMN IF EXISTS previous_value cascade, 
DROP COLUMN IF EXISTS percent_change cascade,
DROP COLUMN IF EXISTS change cascade,
DROP COLUMN IF EXISTS created_at,
DROP COLUMN IF EXISTS year_month,
DROP COLUMN IF EXISTS company_name,
DROP COLUMN IF EXISTS timestamp_date,
DROP COLUMN IF EXISTS first_month_close, 
DROP COLUMN IF EXISTS YTD,
DROP COLUMN IF EXISTS timestamp_month, 
DROP COLUMN IF EXISTS timestamp_year;")

#add columns to db
conn.exec("ALTER TABLE stock_prices_monthly 
ADD COLUMN average_price NUMERIC,
ADD COLUMN previous_value NUMERIC,
ADD COLUMN first_month_close NUMERIC,
ADD COLUMN YTD NUMERIC,
ADD COLUMN year_month VARCHAR(10),
ADD COLUMN timestamp_date DATE,
ADD COLUMN company_name TEXT,
ADD COLUMN timestamp_month text,
ADD COLUMN timestamp_year text;")



#add average_price column for monthly
conn.exec("UPDATE stock_prices_monthly SET average_price= ROUND((open + high + low + close) / 4,3);")


#inserting data to previous_value column monthly
conn.exec("UPDATE stock_prices_monthly
SET previous_value = subquery.previous_value
FROM (
    SELECT
        symbol,
        timestamp,
        LAG(close) OVER (PARTITION BY symbol ORDER BY symbol, timestamp) AS previous_value
    FROM stock_prices_monthly
) AS subquery
WHERE stock_prices_monthly.symbol = subquery.symbol AND stock_prices_monthly.timestamp = subquery.timestamp;")

# add computed columns for change & %_change monthly
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN percent_change NUMERIC generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN change NUMERIC generated always AS (round(open - previous_value, 3)) stored;")

#add column for first_month_close and ytd
conn.exec("UPDATE stock_prices_monthly
SET first_month_close = (
    SELECT close
    FROM stock_prices_monthly AS t2
    WHERE EXTRACT(YEAR FROM t2.timestamp) = EXTRACT(YEAR FROM stock_prices_monthly.timestamp)
    ORDER BY symbol, t2.timestamp
    LIMIT 1
);")
conn.exec("UPDATE stock_prices_monthly SET YTD = ROUND(((close - first_month_close) / first_month_close) * 100, 3);")

#add column for year_month ex."2023-Apr"
conn.exec("UPDATE stock_prices_monthly SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add column for timestamp_date ex. "2023-04-28"
conn.exec("UPDATE stock_prices_monthly SET timestamp_date = CAST(timestamp AS DATE);")

#add column name for company name
conn.exec("UPDATE stock_prices_monthly
SET company_name = 
  CASE
  WHEN symbol = 'AAPL' THEN 'Apple Inc.'
  WHEN symbol = 'MSFT' THEN 'Microsoft Corporation'
	WHEN symbol = 'GOOGL' THEN 'Alphabet Inc. (Google)'
	WHEN symbol = 'AMZN' THEN 'Amazon.com Inc.'
	WHEN symbol = 'TSLA' THEN 'Tesla Inc.'
	WHEN symbol = 'JNJ' THEN 'Johnson & Johnson'
	WHEN symbol = 'JPM' THEN 'JPMorgan Chase & Co.'
	WHEN symbol = 'PG' THEN 'Procter & Gamble Co.'
	WHEN symbol = 'V' THEN 'Visa Inc.'
	WHEN symbol = 'KO' THEN 'The Coca-Cola Company '
  ELSE ''
  END;")

#add columns for timestamp year, month
conn.exec("UPDATE stock_prices_monthly
SET timestamp_month = to_char(timestamp, 'Month'),
timestamp_year = to_char(timestamp, 'YYYY');")


#add column for created_at (date_time of insertion to db)
conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
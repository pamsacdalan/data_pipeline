require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)

conn.exec("SET TIME ZONE 'UTC-8';")

#add columns to stock_prices_weekly if the necessary (fetched) columns exist
conn.exec("DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'stock_prices_weekly' AND 
    column_name IN ('timestamp', 'symbol', 'open', 'high', 'low', 'close', 'volume')
  ) THEN
    ALTER TABLE stock_prices_weekly
    ADD COLUMN IF NOT EXISTS average_price NUMERIC,
    ADD COLUMN IF NOT EXISTS previous_value NUMERIC,
    ADD COLUMN IF NOT EXISTS percent_change NUMERIC,
	  ADD COLUMN IF NOT EXISTS change NUMERIC,
    ADD COLUMN IF NOT EXISTS year_month VARCHAR(10),
    ADD COLUMN IF NOT EXISTS week_no TEXT,
    ADD COLUMN IF NOT EXISTS timestamp_year text,
    ADD COLUMN IF NOT EXISTS timestamp_month TEXT,
    ADD COLUMN IF NOT EXISTS timestamp_date DATE,    
    ADD COLUMN IF NOT EXISTS company_name TEXT,
	  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;")

#add/update data on average_price column for weekly
conn.exec("UPDATE stock_prices_weekly SET average_price= ROUND((open + high + low + close) / 4,3);")

#add/update data on previous_value column weekly
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

#add/update data on percent_change & change on columns
conn.exec("UPDATE stock_prices_weekly SET percent_change = round((open - previous_value) / previous_value * 100, 3)")
conn.exec("UPDATE stock_prices_weekly SET change = round(open - previous_value, 3)")

#add/update data on year_month column ex."2023-Apr"
conn.exec("UPDATE stock_prices_weekly SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add/update data on week_no (1-4), timestamp_month (January-December), timestamp_year (2023) columns
conn.exec("UPDATE stock_prices_weekly
SET week_no = to_char(timestamp, 'W'),
timestamp_month = to_char(timestamp, 'Month'),
timestamp_year = to_char(timestamp, 'YYYY');")

#add/update data on timestamp_date & created_at columns
conn.exec("UPDATE stock_prices_weekly SET timestamp_date = CAST(timestamp AS DATE), created_at = CURRENT_TIMESTAMP;")

#add column for company name
conn.exec("UPDATE stock_prices_weekly
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

# Close the database connection
conn.close
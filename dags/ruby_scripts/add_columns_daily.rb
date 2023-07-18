require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)

conn.exec("SET TIME ZONE 'UTC-8';")

#add columns to stock_prices_daily if the necessary (fetched) columns exist
conn.exec("DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'stock_prices_daily' AND 
    column_name IN ('timestamp', 'symbol', 'open', 'high', 'low', 'close', 'volume')
  ) THEN
    ALTER TABLE stock_prices_daily
    ADD COLUMN IF NOT EXISTS average_price NUMERIC,
    ADD COLUMN IF NOT EXISTS percent_change NUMERIC,
	  ADD COLUMN IF NOT EXISTS change NUMERIC,
    ADD COLUMN IF NOT EXISTS first_day_close NUMERIC,
    ADD COLUMN IF NOT EXISTS YTD NUMERIC,
    ADD COLUMN IF NOT EXISTS year_month VARCHAR(10),
    ADD COLUMN IF NOT EXISTS timestamp_date DATE,
    ADD COLUMN IF NOT EXISTS timestamp_day TEXT,
    ADD COLUMN IF NOT EXISTS timestamp_month TEXT,
    ADD COLUMN IF NOT EXISTS timestamp_year text,
    ADD COLUMN IF NOT EXISTS company_name TEXT,
	  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;")


#add/update data to average_price column for daily
conn.exec("UPDATE stock_prices_daily SET average_price= ROUND((open + high + low + close) / 4,3);")

# add/update data for percent_change and change columns
conn.exec("UPDATE stock_prices_daily SET percent_change = round((close - open) / open * 100, 3)")
conn.exec("UPDATE stock_prices_daily SET change = round(close - open, 3)")

# add/update data to column for first_day_close (used for ytd computation)
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

#add/update ytd column
conn.exec("UPDATE stock_prices_daily SET ytd = round(((close-first_day_close)/first_day_close)*100,3);")

#add/update data to column for year_month ex."2023-Apr"
conn.exec("UPDATE stock_prices_daily SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add/update data to column for timestamp_date
conn.exec("UPDATE stock_prices_daily SET timestamp_date = CAST(timestamp AS DATE);")

#add/update data to company name column
conn.exec("UPDATE stock_prices_daily
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


#add/update data to timestamp year, month, day amd created_at columns
conn.exec("UPDATE stock_prices_daily
SET timestamp_day = EXTRACT(DAY FROM timestamp),
timestamp_month = to_char(timestamp, 'Month'),
timestamp_year = to_char(timestamp, 'YYYY'),
created_at = CURRENT_TIMESTAMP;")


# Close the database connection
conn.close
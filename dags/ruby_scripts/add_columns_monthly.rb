require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)

conn.exec("SET TIME ZONE 'UTC-8';")

#add columns to stock_prices_monthly if the necessary (fetched) columns exist
conn.exec("DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'stock_prices_monthly' AND 
    column_name IN ('timestamp', 'symbol', 'open', 'high', 'low', 'close', 'volume')
  ) THEN
    ALTER TABLE stock_prices_monthly
    ADD COLUMN IF NOT EXISTS average_price NUMERIC,
    ADD COLUMN IF NOT EXISTS percent_change NUMERIC,
	  ADD COLUMN IF NOT EXISTS change NUMERIC,
    ADD COLUMN IF NOT EXISTS first_month_close NUMERIC,
    ADD COLUMN IF NOT EXISTS YTD NUMERIC,
    ADD COLUMN IF NOT EXISTS year_month VARCHAR(10),
    ADD COLUMN IF NOT EXISTS timestamp_date DATE,
    ADD COLUMN IF NOT EXISTS timestamp_month TEXT,
    ADD COLUMN IF NOT EXISTS timestamp_year text,
    ADD COLUMN IF NOT EXISTS company_name TEXT,
	  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;")

#add/update data for average_price column on monthly
conn.exec("UPDATE stock_prices_monthly SET average_price= ROUND((open + high + low + close) / 4,3);")

#add/update data for percent_change & change columns
conn.exec("UPDATE stock_prices_monthly SET percent_change = round((close - open) / open * 100, 3)")
conn.exec("UPDATE stock_prices_monthly SET change = round(close - open, 3)")

#add/update data for first_month_close and ytd columns
conn.exec("UPDATE stock_prices_monthly
SET first_month_close = (
    SELECT close
    FROM stock_prices_monthly AS t2
    WHERE EXTRACT(YEAR FROM t2.timestamp) = EXTRACT(YEAR FROM stock_prices_monthly.timestamp)
    ORDER BY symbol, t2.timestamp
    LIMIT 1 );")
conn.exec("UPDATE stock_prices_monthly SET YTD = ROUND(((close - first_month_close) / first_month_close) * 100, 3);")

#add/update data for year_month column ex."2023-Apr"
conn.exec("UPDATE stock_prices_monthly SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add/update data for timestamp_date column ex. "2023-04-28"
conn.exec("UPDATE stock_prices_monthly SET timestamp_date = CAST(timestamp AS DATE);")

#add/update data for company name column
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

#add/update data for for timestamp year, month & created_at columns
conn.exec("UPDATE stock_prices_monthly
SET timestamp_month = to_char(timestamp, 'Month'),
timestamp_year = to_char(timestamp, 'YYYY'),
created_at = CURRENT_TIMESTAMP;")

# Close the database connection
conn.close
require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)

conn.exec("SET TIME ZONE 'UTC-8';")

#add columns to stock_prices_intraday if the necessary (fetched) columns exist
conn.exec("DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns 
    WHERE table_name = 'stock_prices_intraday' AND 
    column_name IN ('timestamp', 'symbol', 'open', 'high', 'low', 'close', 'volume')
  ) THEN
    ALTER TABLE stock_prices_intraday
    ADD COLUMN IF NOT EXISTS average_price NUMERIC,
    ADD COLUMN IF NOT EXISTS year_month VARCHAR(10),
    ADD COLUMN IF NOT EXISTS timestamp_date DATE,
    ADD COLUMN IF NOT EXISTS timestamp_time TEXT,
    ADD COLUMN IF NOT EXISTS company_name TEXT,
	ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;")

#add data to average_price column for intraday
conn.exec("UPDATE stock_prices_intraday SET average_price= ROUND((open + high + low + close) / 4,3);")

#add data to column for year_month ex."2023-Apr"
conn.exec("UPDATE stock_prices_intraday SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add data to columns for timestamp_date, timestamp_time
conn.exec("UPDATE stock_prices_intraday
SET timestamp_date = CAST(timestamp AS DATE),
    timestamp_time = CAST(timestamp AS TIME),
	created_at = CURRENT_TIMESTAMP;")

#add data to column for company name
conn.exec("UPDATE stock_prices_intraday
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
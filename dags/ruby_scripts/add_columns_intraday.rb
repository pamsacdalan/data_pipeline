require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("ALTER TABLE stock_prices_intraday DROP COLUMN IF EXISTS average_price,
DROP COLUMN IF EXISTS created_at,
DROP COLUMN IF EXISTS year_month,
DROP COLUMN IF EXISTS company_name,
DROP COLUMN IF EXISTS timestamp_date,
DROP COLUMN IF EXISTS timestamp_time;")

#add columns to db
conn.exec("ALTER TABLE stock_prices_intraday 
ADD COLUMN average_price NUMERIC,
ADD COLUMN year_month VARCHAR(10),
ADD COLUMN timestamp_date DATE,
ADD COLUMN timestamp_time TIME,
ADD COLUMN company_name TEXT;")

#add data to average_price column for intraday
conn.exec("UPDATE stock_prices_intraday SET average_price= ROUND((open + high + low + close) / 4,3);")

#add data to column for year_month ex."2023-Apr"
conn.exec("UPDATE stock_prices_intraday SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

#add data to columns for timestamp_date, timestamp_time
conn.exec("UPDATE stock_prices_intraday
SET timestamp_date = CAST(timestamp AS DATE),
    timestamp_time = CAST(timestamp AS TIME);")

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


#add column for created_at (date_time of insertion to db)
conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_intraday ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
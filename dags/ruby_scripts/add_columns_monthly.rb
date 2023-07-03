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
DROP COLUMN IF EXISTS YTD;")

#add average_price column for monthly
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN average_price numeric;")
conn.exec("UPDATE stock_prices_monthly SET average_price= ROUND((open + high + low + close) / 4,3);")

#adding previous_value column to monthly
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN previous_value numeric;")

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
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")

conn.exec("ALTER TABLE stock_prices_monthly ADD first_month_close numeric, ADD YTD numeric;")
conn.exec("UPDATE stock_prices_monthly
SET first_month_close = (
    SELECT close
    FROM stock_prices_monthly AS t2
    WHERE EXTRACT(YEAR FROM t2.timestamp) = EXTRACT(YEAR FROM stock_prices_monthly.timestamp)
    ORDER BY symbol, t2.timestamp
    LIMIT 1
);")
conn.exec("UPDATE stock_prices_monthly SET YTD = ROUND(((close - first_month_close) / first_month_close) * 100, 3);")


conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN year_month VARCHAR(10);")
conn.exec("UPDATE stock_prices_monthly SET year_month = CONCAT(EXTRACT(YEAR FROM timestamp), '-', TO_CHAR(timestamp, 'Mon'));")

conn.exec("ALTER TABLE stock_prices_monthly ADD timestamp_date DATE;")
conn.exec("UPDATE stock_prices_monthly SET timestamp_date = CAST(timestamp AS DATE);")

conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN company_name TEXT;")
conn.exec("UPDATE stock_prices_monthly
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

conn.exec("SET TIME ZONE 'UTC-8';")
conn.exec("ALTER TABLE stock_prices_monthly ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
# Close the database connection
conn.close
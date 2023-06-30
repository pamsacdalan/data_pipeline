require 'pg'
require_relative 'config'

# Establish a connection to your PostgreSQL database
db_config = Config::DB_CONFIG
conn = PG.connect(db_config)


# Execute an SQL command to add the computed column
conn.exec("alter table stock_prices_intraday drop column if exists average_price;")
conn.exec("alter table stock_prices_daily drop column if exists average_price;")
conn.exec("alter table stock_prices_weekly drop column if exists average_price;")
conn.exec("alter table stock_prices_monthly drop column if exists average_price;")

#drop columns for stock_prices_daily
conn.exec("alter table stock_prices_daily 
drop column if exists previous_value cascade, 
drop column if exists percent_change cascade,
drop column if exists change cascade;")

#drop columns for stock_prices_weekly
conn.exec("alter table stock_prices_weekly 
drop column if exists previous_value cascade, 
drop column if exists percent_change cascade,
drop column if exists change cascade;")

#drop columns for stock_prices_monthly
conn.exec("alter table stock_prices_monthly 
drop column if exists previous_value cascade, 
drop column if exists percent_change cascade,
drop column if exists change cascade;")


#add average_price column for daily
conn.exec("alter table stock_prices_daily ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_daily set average_price= ROUND((open + high + low + close) / 4,3);")

#add average_price column for weekly
conn.exec("alter table stock_prices_weekly ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_weekly set average_price= ROUND((open + high + low + close) / 4,3);")

#add average_price column for monthly
conn.exec("alter table stock_prices_monthly ADD COLUMN average_price numeric;")
conn.exec("update stock_prices_monthly set average_price= ROUND((open + high + low + close) / 4,3);")

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

# # add computed columns for change & %_change
conn.exec("alter table stock_prices_daily ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("alter table stock_prices_daily ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")

#--------------
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

#------- monthly
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
conn.exec("alter table stock_prices_monthly ADD COLUMN percent_change numeric generated always AS (round((open - previous_value) / previous_value * 100, 3)) stored;")
conn.exec("alter table stock_prices_monthly ADD COLUMN change numeric generated always AS (round(open - previous_value, 3)) stored;")



# Close the database connection
conn.close
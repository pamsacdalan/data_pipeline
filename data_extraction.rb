require 'httparty'
require 'csv'
require 'pg'
require_relative 'config'


api_key = Config::API_KEY
interval = Config::INTERVAL
symbols = Config::SYMBOLS
scheds = Config::SCHEDS
db_config = Config::DB_CONFIG

conn = PG.connect(db_config)

scheds.each do |sched|
  symbols.each do |symbol|
    # Create HTTP request using Alpha Vantage API
    #response = HTTParty.get("https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=#{symbol}&interval=#{interval}&apikey=#{api_key}")
    response = HTTParty.get("https://www.alphavantage.co/query?function=TIME_SERIES_#{sched}&symbol=#{symbol}&interval=#{interval}&apikey=#{api_key}")


    # Process the request
    if sched == 'INTRADAY'
      parsed_data = JSON.parse(response.body)['Time Series (5min)']
    elsif sched == 'DAILY_ADJUSTED'
      parsed_data = JSON.parse(response.body)['Time Series (Daily)']
    elsif sched == 'WEEKLY'
      parsed_data = JSON.parse(response.body)['Weekly Time Series']
    elsif sched == 'MONTHLY'
      parsed_data = JSON.parse(response.body)['Monthly Time Series']
    end

    processed_data = parsed_data.map do |timestamp, values|
      volume = if sched == 'INTRADAY' || sched == 'MONTHLY' || sched == 'WEEKLY'
        values['5. volume'].to_i
      elsif sched == 'DAILY_ADJUSTED'
        values['6. volume'].to_i
      end
      {
        timestamp: Time.parse(timestamp).iso8601,
        symbol: symbol,
        open: values['1. open'].to_f,
        high: values['2. high'].to_f,
        low: values['3. low'].to_f,
        close: values['4. close'].to_f,
        volume: volume
      }
    end

    # Create table in the db if it doesn't exist
    if sched == 'INTRADAY'
      conn.exec('CREATE TABLE IF NOT EXISTS stock_prices_intraday (
        timestamp TIMESTAMP,
        symbol TEXT,
        open NUMERIC,
        high NUMERIC,
        low NUMERIC,
        close NUMERIC,
        volume BIGINT
      )')
      # conn.exec('DELETE FROM stock_prices_intraday')
      # processed_data.each do |row|
      #      timestamp = row[:timestamp]
      #      symbol = row[:symbol]
      #   conn.exec_params('INSERT INTO stock_prices_intraday (timestamp, symbol, open, high, low, close, volume) 
      #       VALUES ($1, $2, $3, $4, $5, $6, $7)', 
      #       [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
      # end
      processed_data.each do |row|
           timestamp = row[:timestamp]
           symbol = row[:symbol]
    
           existing_data = conn.exec_params('SELECT COUNT(*) FROM stock_prices_intraday WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i
    
           if existing_data.zero?
             conn.exec_params('INSERT INTO stock_prices_intraday (timestamp, symbol, open, high, low, close, volume) 
               VALUES ($1, $2, $3, $4, $5, $6, $7)', 
               [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
           elsif existing_data == 1
             conn.exec_params('UPDATE stock_prices_intraday SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
               [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
           end
      end


    elsif sched == 'DAILY_ADJUSTED'
      conn.exec('CREATE TABLE IF NOT EXISTS stock_prices_daily (
        timestamp TIMESTAMP,
        symbol TEXT,
        open NUMERIC,
        high NUMERIC,
        low NUMERIC,
        close NUMERIC,
        volume BIGINT
      )')
      processed_data.each do |row|
        timestamp = row[:timestamp]
        symbol = row[:symbol]
 
        existing_data = conn.exec_params('SELECT COUNT(*) FROM stock_prices_daily WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i
 
        if existing_data.zero?
          conn.exec_params('INSERT INTO stock_prices_daily (timestamp, symbol, open, high, low, close, volume) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)', 
            [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
        elsif existing_data == 1
          conn.exec_params('UPDATE stock_prices_daily SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
            [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
        end
      end

    elsif sched == 'WEEKLY'
      conn.exec('CREATE TABLE IF NOT EXISTS stock_prices_weekly (
        timestamp TIMESTAMP,
        symbol TEXT,
        open NUMERIC,
        high NUMERIC,
        low NUMERIC,
        close NUMERIC,
        volume BIGINT
      )')
      processed_data.each do |row|
        timestamp = row[:timestamp]
        symbol = row[:symbol]
 
        existing_data = conn.exec_params('SELECT COUNT(*) FROM stock_prices_weekly WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i
 
        if existing_data.zero?
          conn.exec_params('INSERT INTO stock_prices_weekly (timestamp, symbol, open, high, low, close, volume) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)', 
            [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
        elsif existing_data == 1
          conn.exec_params('UPDATE stock_prices_weekly SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
            [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
        end
      end

    elsif sched == 'MONTHLY'
      conn.exec('CREATE TABLE IF NOT EXISTS stock_prices_monthly (
        timestamp TIMESTAMP,
        symbol TEXT,
        open NUMERIC,
        high NUMERIC,
        low NUMERIC,
        close NUMERIC,
        volume BIGINT
      )')
      processed_data.each do |row|
        timestamp = row[:timestamp]
        symbol = row[:symbol]
 
        existing_data = conn.exec_params('SELECT COUNT(*) FROM stock_prices_monthly WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i
 
        if existing_data.zero?
          conn.exec_params('INSERT INTO stock_prices_monthly (timestamp, symbol, open, high, low, close, volume) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)', 
            [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
        elsif existing_data == 1
          conn.exec_params('UPDATE stock_prices_monthly SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
            [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
        end
      end
    end

    # Insert or update processed data in the table
    # processed_data.each do |row|
    #   timestamp = row[:timestamp]
    #   symbol = row[:symbol]

    #   existing_data = conn.exec_params('SELECT COUNT(*) FROM stock_prices WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i

    #   if existing_data.zero?
    #     conn.exec_params('INSERT INTO stock_prices (timestamp, symbol, open, high, low, close, volume) 
    #       VALUES ($1, $2, $3, $4, $5, $6, $7)', 
    #       [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
    #   elsif existing_data == 1
    #     conn.exec_params('UPDATE stock_prices SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
    #       [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
    #   end
    # end
    sleep(60)
  end
  sleep(60)
end

# Close the database connection
conn.close

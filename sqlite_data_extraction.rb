require 'httparty'
require 'csv'
require 'sqlite3'

# Set API key, symbol, and interval
api_key = 'GKAUVT5XYYF5OFH3'
interval = '5min'
symbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'BABA']

symbols.each do |symbol|

  # Create HTTP request using Alpha Vantage API
  response = HTTParty.get("https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=#{symbol}&interval=#{interval}&apikey=#{api_key}")

  # Process the request
  parsed_data = JSON.parse(response.body)['Time Series (5min)']
  processed_data = parsed_data.map do |timestamp, values|
    {
      timestamp: Time.parse(timestamp).iso8601,
      symbol: symbol,
      open: values['1. open'].to_f,
      high: values['2. high'].to_f,
      low: values['3. low'].to_f,
      close: values['4. close'].to_f,
      volume: values['5. volume'].to_i
  }
  end
  # Store the data in SQLite
  db_path = '/mnt/c/Users/BVILLAMIL/Desktop/rails/financial_data_pipeline/financial_data.db'
  db = SQLite3::Database.new(db_path)

  # Create table in the db
  db.execute('CREATE TABLE IF NOT EXISTS stock_prices
  (
      timestamp TIMESTAMP,
      symbol TEXT,
      open NUMERIC,
      high NUMERIC,
      low NUMERIC,
      close NUMERIC,
      volume INT
  )')

  # Insert processed data into table making sure there will be no duplicate records every dags run
  processed_data.each do |row|
      timestamp = row[:timestamp]
      symbol = row[:symbol]

      existing_data = db.get_first_value('SELECT COUNT(*) FROM stock_prices WHERE timestamp = ? AND symbol = ?', [timestamp, symbol])

      if existing_data.zero?
        db.execute('INSERT INTO stock_prices (timestamp, symbol, open, high, low, close, volume) 
        VALUES (?, ?, ?, ?, ?, ?, ?)', 
        [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]])
      elsif existing_data == 1
        db.execute('UPDATE stock_prices SET open = ?, high = ?, low = ?, close = ?, volume = ? WHERE timestamp = ? AND symbol = ?', 
        [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol])
      end
    end

  # Close the db
  db.close
end
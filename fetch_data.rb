require 'httparty'
require_relative 'config'


api_key = Config::API_KEY
interval = Config::INTERVAL
# symbols = Config::SYMBOLS
# scheds = Config::SCHEDS


symbols = ['AAPL']
scheds = ['INTRADAY']


fetch_data = {}

scheds.each do |sched|
  symbols.each do |symbol|
    # Create HTTP request using Alpha Vantage API
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
    # puts parsed_data
    processed_data = parsed_data.map do |timestamp, values|
      volume = if sched == 'INTRADAY' || sched == 'MONTHLY' || sched == 'WEEKLY'
        values['5. volume'].to_i
      elsif sched == 'DAILY_ADJUSTED'
        values['6. volume'].to_i
      end
      { 
        sched: sched,
        timestamp: Time.parse(timestamp).iso8601,
        symbol: symbol,
        open: values['1. open'].to_f,
        high: values['2. high'].to_f,
        low: values['3. low'].to_f,
        close: values['4. close'].to_f,
        volume: volume
      }
    end
    puts processed_data
    sleep(60)
  end
  sleep(60)
end


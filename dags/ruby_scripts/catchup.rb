require 'date'
require 'httparty'
require 'csv'
require 'pg'
require_relative 'config'

api_key = Config::API_KEY
interval = Config::INTERVAL
symbols = Config::SYMBOLS
db_config = Config::DB_CONFIG

catchup_date = []

puts "Type the number of the table that you want to catch-up"
puts "1. INTRADAY"
puts "2. DAILY"
puts "3. WEEKLY"
puts "4. MONTHLY"

table_number = nil

# loop until user inputs a number between 1-4
until (1..4).include?(table_number)
  print "Enter the table number: "
  table_number = gets.chomp.to_i
end


#accepts only date in YYYY-MM-DD format
#returns true if correct date format
def valid_date_format?(date_string)
    # Validate against the format YYYY-MM-DD
    valid_format = /\A\d{4}-\d{2}-\d{2}\z/.match?(date_string)
  
    # Ensure the parsed date is valid
    valid_format && Date.parse(date_string)
  rescue ArgumentError
    false
  end

#create catchup_date table
  def get_date_range
    loop do
      puts "Enter the start date (YYYY-MM-DD): "
      start_date_input = gets.chomp.strip #remove leading and trailing spaces
      puts "Enter the end date (YYYY-MM-DD): "
      end_date_input = gets.chomp.strip
  
      if !valid_date_format?(start_date_input) || !valid_date_format?(end_date_input)
        puts "Invalid Date Format."
        next
      end
  
      start_date = Date.parse(start_date_input)
      end_date = Date.parse(end_date_input)
  
      if start_date > end_date
        puts "Start Date MUST be before End Date."
        next
      end
  
      catchup_date = []
      current_date = start_date
  
      while current_date <= end_date
        catchup_date << current_date.strftime("%Y-%m-%d")
        current_date = current_date.next_day
      end
  
      return catchup_date
    end
  end
  
  if table_number == 1
    sched = 'INTRADAY'
  elsif table_number == 2
    sched = 'DAILY_ADJUSTED'
  elsif table_number == 3
    sched = 'WEEKLY'
  elsif table_number == 4
    sched = 'MONTHLY'
  end
  
  catchup_date = get_date_range


year_month = []
catchup_date.each do |date|
    year_month << Date.parse(date).strftime("%Y-%m")
end


# Get the unique dates from the catchup_date table
catchup_date = catchup_date.uniq
year_month = year_month.uniq

conn = PG.connect(db_config)

#create table if it does not exist yet
def create_table(conn, table_name)
    conn.exec("CREATE TABLE IF NOT EXISTS #{table_name}(
                timestamp TIMESTAMP,
                symbol TEXT,
                open NUMERIC,
                high NUMERIC,
                low NUMERIC,
                close NUMERIC,
                volume BIGINT
              )")
end

if sched == 'INTRADAY'
  year_month.each do |date|
        symbols.each do |symbol|
            puts "Fetching #{sched} #{symbol} Data for #{catchup_date.first} to #{catchup_date.last}"

          # Process the request
              response = HTTParty.get("https://www.alphavantage.co/query?function=TIME_SERIES_#{sched}&symbol=#{symbol}&interval=#{interval}&month=#{date}&outputsize=full&apikey=#{api_key}")
              parsed_data = JSON.parse(response.body)["Time Series (5min)"]
              processed_data = parsed_data.map do |timestamp, values|
                if catchup_date.include?(timestamp.split(' ')[0]) 
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
              end.compact
              table_name = "stock_prices_intraday" 
              #run create_table function
              create_table(conn, table_name)
              # Insert or update the data in the table
              processed_data.each do |row|
                  timestamp = row[:timestamp]
                  symbol = row[:symbol]
                  existing_data = conn.exec_params(
                    "SELECT COUNT(*) FROM #{table_name} WHERE timestamp = $1 AND symbol = $2",
                    [timestamp, symbol]
                  ).getvalue(0, 0).to_i

                  if existing_data.zero?
                    conn.exec_params(
                      "INSERT INTO #{table_name} (timestamp, symbol, open, high, low, close, volume) 
                      VALUES ($1, $2, $3, $4, $5, $6, $7)",
                      [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]]
                    )
                  elsif existing_data == 1
                    conn.exec_params(
                      "UPDATE #{table_name} SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7",
                      [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol]
                    )
                  end
                end          
              puts "#{sched} #{symbol} Data for #{catchup_date.first} to #{catchup_date.last} Successfully Fetched and Stored to #{table_name}"
          sleep(15)
        end       
    sleep(15)
  end

else
  symbols.each do |symbol|
    puts "Fetching #{sched} #{symbol} Data for #{catchup_date.first} to #{catchup_date.last}"
    response = HTTParty.get("https://www.alphavantage.co/query?function=TIME_SERIES_#{sched}&symbol=#{symbol}&interval=#{interval}&outputsize=full&apikey=#{api_key}")
    # Process the request
    
    if sched == 'DAILY_ADJUSTED'
        parsed_data = JSON.parse(response.body)['Time Series (Daily)']
        processed_data = parsed_data.map do |timestamp, values|
          #matches each catchup_date to the timestamp date value and get the elements of the timestamp
          if catchup_date.include?(timestamp.split(' ')[0]) 
              {
                  timestamp: Time.parse(timestamp).iso8601,
                  symbol: symbol,
                  open: values['1. open'].to_f,
                  high: values['2. high'].to_f,
                  low: values['3. low'].to_f,
                  close: values['4. close'].to_f,
                  volume: values['6. volume'].to_i
                }
          end
        end.compact
    elsif sched == 'WEEKLY'
        parsed_data = JSON.parse(response.body)['Weekly Time Series']
        processed_data = parsed_data.map do |timestamp, values|
          if catchup_date.include?(timestamp.split(' ')[0]) 
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
        end.compact
    elsif sched == 'MONTHLY'
        parsed_data = JSON.parse(response.body)['Monthly Time Series']
        processed_data = parsed_data.map do |timestamp, values|
          if catchup_date.include?(timestamp.split(' ')[0]) 
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
        end.compact
    end
    # set the table_name based on what table you want to catch-up  
    table_name = case sched
                 when "DAILY_ADJUSTED"
                   "stock_prices_daily"
                 when "WEEKLY"
                   "stock_prices_weekly"
                 when "MONTHLY"
                   "stock_prices_monthly"
                 end
    
    #run create_table function
    create_table(conn, table_name)
    # Insert or update the data in the table
    processed_data.each do |row|
        timestamp = row[:timestamp]
        symbol = row[:symbol]
      
        existing_data = conn.exec_params(
          "SELECT COUNT(*) FROM #{table_name} WHERE timestamp = $1 AND symbol = $2",
          [timestamp, symbol]
        ).getvalue(0, 0).to_i
      
        if existing_data.zero?
          conn.exec_params(
            "INSERT INTO #{table_name} (timestamp, symbol, open, high, low, close, volume) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)",
            [row[:timestamp], row[:symbol], row[:open], row[:high], row[:low], row[:close], row[:volume]]
          )
        elsif existing_data == 1
          conn.exec_params(
            "UPDATE #{table_name} SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7",
            [row[:open], row[:high], row[:low], row[:close], row[:volume], timestamp, symbol]
          )
        end
      end          
    puts "#{sched} #{symbol} Data for #{catchup_date.first} to #{catchup_date.last} Successfully Fetched and Stored to #{table_name}"
    sleep(15)
  end
end
  

# Close the database connection
conn.close

#run add_columns file depending on which table you want to catchup
puts "Adding Additional columns to #{sched} table"
if sched == 'INTRADAY'
  load 'add_columns_intraday.rb'
elsif sched == 'DAILY_ADJUSTED'
  load 'add_columns_daily.rb'
elsif sched == 'WEEKLY'
  load 'add_columns_weekly.rb'
else
load 'add_columns_monthly.rb'
end
puts "Additional Columns Successfully Stored to #{sched} table"
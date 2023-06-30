require 'pg' 
require_relative 'config'


db_config = Config::DB_CONFIG
conn = PG.connect(db_config)
data = $stdin.read
hash_strings = data.strip.split("\n")

# Convert each hash representation to a Ruby hash
hashes = hash_strings.map { |hash_string| eval(hash_string)}

hashes.each do |hash|
# Create table in the db if it doesn't exist
    if hash[:sched] == 'MONTHLY'
        conn.exec('CREATE TABLE IF NOT EXISTS test_stock_prices_monthly_JASON (
        timestamp TIMESTAMP,
        symbol TEXT,
        open NUMERIC,
        high NUMERIC,
        low NUMERIC,
        close NUMERIC,
        volume BIGINT
        )')
    
        timestamp = hash[:timestamp]
        symbol = hash[:symbol]
        existing_data = conn.exec_params('SELECT COUNT(*) FROM test_stock_prices_monthly_JASON WHERE timestamp = $1 AND symbol = $2', [timestamp, symbol]).getvalue(0, 0).to_i
        if existing_data.zero?
        conn.exec_params('INSERT INTO test_stock_prices_monthly_JASON (timestamp, symbol, open, high, low, close, volume) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)', 
            [hash[:timestamp], hash[:symbol], hash[:open], hash[:high], hash[:low], hash[:close], hash[:volume]])
        elsif existing_data == 1
        conn.exec_params('UPDATE test_stock_prices_monthly_JASON SET open = $1, high = $2, low = $3, close = $4, volume = $5 WHERE timestamp = $6 AND symbol = $7', 
            [hash[:open], hash[:high], hash[:low], hash[:close], hash[:volume], timestamp, symbol])
        end
    end
end

# Close the database connection
conn.close
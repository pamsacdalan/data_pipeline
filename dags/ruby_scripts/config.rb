module Config
    #API_KEY = 'FP360U9Q9JMBBA5I'
    API_KEY = 'GKAUVT5XYYF5OFH3'
    INTERVAL = '5min'
    SYMBOLS = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'JNJ', 'JPM', 'PG', 'V', 'KO']
    SCHEDS = ['INTRADAY', 'DAILY_ADJUSTED', 'WEEKLY', 'MONTHLY']

# Establish PostgreSQL connection
    DB_CONFIG = {
    host: 'ep-hidden-salad-492177.ap-southeast-1.aws.neon.tech',
    port: '5432',
     dbname: 'data_pipeline',
     user: 'jasonroberto38',
     password: 'fULOsTQa54tp'
    }
end

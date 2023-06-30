class HomeController < ApplicationController
  def index
  end

  def dashboard
  end

  def daily
    symbol = params[:symbol] # Get the selected symbol from the filter
  
    if symbol.present? # If a symbol is selected, filter the data accordingly
      @chart_data = StockPricesDaily.where(symbol: symbol)
                    .group("to_char(timestamp, 'YYYY-MM')")
                    .sum(:close)
    else # If no symbol is selected, fetch all data
      @chart_data = StockPricesDaily.group("to_char(timestamp, 'YYYY-MM')")
                    .sum(:close)
    end
  
    render 'daily'
  end
  
  def weekly
    @weekly_data = StockPricesWeekly.all
    @weeklies = StockPricesWeekly.group(:symbol).select(:symbol).select("AVG(average_price) AS average_price").select("AVG(percent_change) AS percent_change")
    
    local_symbols = ['AAA', 'SM', 'TEL', 'GLO', 'UBP']
    local_weekly = @weekly_data.select { |weekly_datum| local_symbols.include?(weekly_datum.symbol) }

    international_symbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA']
    international_weekly = @weekly_data.select { |weekly_datum| international_symbols.include?(weekly_datum.symbol) }
  
  end

  
  
end

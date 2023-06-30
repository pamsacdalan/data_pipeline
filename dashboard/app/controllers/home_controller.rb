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
    # Default: All companies
    @stock_prices = StockPricesWeekly.where("(symbol, timestamp) IN (
      SELECT symbol, MAX(timestamp)
      FROM stock_prices_weekly
      GROUP BY symbol
    )").select(:symbol, :close, :percent_change, :average_price, :year_month)

    @charts = StockPricesWeekly.select(:symbol, :average_price, :year_month)

    local  =  ['AAA', 'SM', 'TEL', 'GLO', 'UBP']
    intl = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA']

    # Region Filter
    if params[:filter].present?
      case params[:filter]
      when 'local'
        @stock_prices = @stock_prices.where(symbol: local)
        @charts = @charts.where(symbol: local)

      when 'international'
        @stock_prices = @stock_prices.where(symbol: intl)
        @charts = @charts.where(symbol: intl)
      end
    end


 


  
  end

end

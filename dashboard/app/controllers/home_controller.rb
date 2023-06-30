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
  
  
  
end

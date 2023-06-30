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
    @weeklies = StockPricesWeekly.where(symbol: ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'AAA', 'SM', 'TEL', 'GLO', 'UBP']).group(:symbol).group(:symbol)
    .select(:symbol)
    .select("MAX(close) AS recent_close")
    .select("AVG(percent_change) AS percent_change")

    # Region Filter
    if params[:filter].present?
      case params[:filter]
      when 'local'
        @weeklies = @weeklies.where(symbol: ['AAA', 'SM', 'TEL', 'GLO', 'UBP']).group(:symbol).select(:symbol).select("MAX(close) AS recent_close").select("AVG(percent_change) AS percent_change")
      when 'international'
        @weeklies = @weeklies.where(symbol: ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA']).group(:symbol).select(:symbol).select("MAX(close) AS recent_close").select("AVG(percent_change) AS percent_change")
      when 'all'
        @weeklies = @weeklies.where(symbol: ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'AAA', 'SM', 'TEL', 'GLO', 'UBP']).group(:symbol).select(:symbol).select("MAX(close) AS recent_close").select("AVG(percent_change) AS percent_change")
      end
    end


    symbol = params[:symbol]
    @symbols = StockPricesWeekly.pluck(:symbol).uniq

    if params[:symbol].present?
      @selected_symbol = params[:symbol]
      @selected_symbol_data = StockPricesWeekly.where(symbol: @selected_symbol).pluck(:year_month, :average_price)
    else
      @selected_symbol_data = StockPricesWeekly.pluck(:year_month, :average_price)
    end
  
  end

end

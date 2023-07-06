class HomeController < ApplicationController
  def index
  end

  def intraday
    @stock_prices = StockPricesIntraday.where("(symbol, timestamp) IN (
      SELECT symbol, MAX(timestamp)
      FROM stock_prices_intraday
      GROUP BY symbol
    )").all

    @intra_stock_prices = StockPricesIntraday.order(timestamp: :asc).all
    @companies = StockPricesIntraday.distinct.pluck(:symbol) # get all companies

    
    # Get the selected symbol from the company filter
    company = params[:company_intraday]
    

    if company.present?
      @filtered_symbols = @companies & @intra_stock_prices.where(symbol: company).pluck(:symbol)
    else
      @filtered_symbols = @companies
    end
    
    @data = @filtered_symbols.map do |filtered_symbol|
        { name: filtered_symbol, data: @intra_stock_prices.where(symbol: filtered_symbol).pluck(:timestamp, :close).to_h }
    end

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
    # Get the data for the table
    @stock_prices = StockPricesWeekly.where("(symbol, timestamp) IN (
      SELECT symbol, MAX(timestamp)
      FROM stock_prices_weekly
      GROUP BY symbol
    )").all

    # Get the selected symbol from the company filter
    company = params[:company_weekly]

    # Data for the area-chart
    @weekly_stock_prices = StockPricesWeekly.order(timestamp: :asc).all
    @companies = StockPricesWeekly.distinct.pluck(:symbol) # get all companies

    

    # Get the ave %chg per symbol throught the year
    @ave_chg_per_year = StockPricesWeekly.select('symbol, AVG(percent_change) AS ave_change, "timestamp"')
                          .where("EXTRACT(YEAR FROM timestamp) = ?", 2023)
                          .group('symbol, "timestamp"')
                          .where(symbol: company)
    
    
    if company.present?
      @filtered_symbols = @companies & @weekly_stock_prices.where(symbol: company).pluck(:symbol)
    else
      @filtered_symbols = @companies
      @ave_chg_per_year = StockPricesWeekly.select('symbol, AVG(percent_change) AS ave_change, "timestamp"')
                                      .where("EXTRACT(YEAR FROM timestamp) = ?", 2023)
                                      .group('symbol, "timestamp"')
    end
    
    # Data for column chart
    @data = @filtered_symbols.map do |filtered_symbol|
      { name: filtered_symbol, data: @weekly_stock_prices.where(symbol: filtered_symbol).pluck(:year_month, :close).to_h }
    end
    
    # Data for the line chart
    @line_chart_data = @ave_chg_per_year.group_by(&:symbol).transform_values do |rows|
      rows.map { |row| [row.timestamp.to_date, row.ave_change] }
    end

    @series_data = @line_chart_data.map { |symbol, values| { name: symbol, data: values } }

  end
end

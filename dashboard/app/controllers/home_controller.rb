class HomeController < ApplicationController
  def index
  end

  def intraday

    # Get the selected symbol from the company filter
    company = params[:company_intraday]

    # Get the selected date range from the date filter
    start_date = params[:start_date]
    end_date = params[:end_date]    
    
    # Set default values for start_date and end_date if they are not selected
    start_date ||= StockPricesIntraday.maximum(:timestamp_date)
    end_date ||= StockPricesIntraday.maximum(:timestamp_date)


    @stock_prices = StockPricesIntraday.where("(symbol, timestamp) IN (
      SELECT symbol, MAX(timestamp)
      FROM stock_prices_intraday
      GROUP BY symbol
    )").all

    @companies = StockPricesIntraday.distinct.pluck(:symbol) # get all companies
    @dates = StockPricesIntraday.distinct.pluck(:timestamp_date)
    @intra_stock_prices = StockPricesIntraday.where(timestamp_date: start_date..end_date).order(timestamp: :asc).all

    if company.present?
      @intra_stock_prices = StockPricesIntraday.where(timestamp_date: start_date..end_date).order(timestamp: :asc).all
      @filtered_symbols = @companies & @intra_stock_prices.where(symbol: company).pluck(:symbol)
      
      if start_date.present? && end_date.present?
        @intra_stock_prices = StockPricesIntraday.where(timestamp_date: start_date..end_date).order(timestamp: :asc).all
        @filtered_symbols = @companies & @intra_stock_prices.where(symbol: company).pluck(:symbol)
      end
      
    else
      @filtered_symbols = @companies
    end
    
    @data = @filtered_symbols.map do |filtered_symbol|
        { name: filtered_symbol, data: @intra_stock_prices.where(symbol: filtered_symbol).pluck(:timestamp, :close).to_h }
    end


  end 
      


  def daily
    @stock_prices = StockPricesDaily.where("(symbol, timestamp) IN (
      SELECT symbol, MAX(timestamp)
      FROM stock_prices_daily
      GROUP BY symbol
      )").order(:timestamp).all

      
    # Data for the area-chart
    @daily_stock_prices = StockPricesDaily.order(timestamp: :asc).all
    @companies = StockPricesDaily.distinct.pluck(:symbol) # get all companies

    # Get the selected symbol from the company filter
    company = params[:company_daily]

    if company.present?
      @filtered_symbols = @companies & @daily_stock_prices.where(symbol: company).pluck(:symbol)
    else
      @filtered_symbols = @companies
    end

        # Data for column chart
    @data = @filtered_symbols.map do |filtered_symbol|
      { name: filtered_symbol, data: @daily_stock_prices.where(symbol: filtered_symbol).pluck(:timestamp_date, :close).to_h }
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


def monthly
  # Get the data for the table

  @charts = StockPricesMonthly.select(:symbol, :percent_change, :year_month)

  @stock_prices = StockPricesMonthly.where("(symbol, year_month) IN (
    SELECT symbol, MAX(year_month)
    FROM stock_prices_monthly
    GROUP BY symbol
    )").order(:year_month, :timestamp).all

  # Get the selected symbol from the company filter
  company = params[:company_monthly]

  # Data for the area-chart
  @monthly_stock_prices = StockPricesMonthly.all
  @companies = StockPricesMonthly.distinct.pluck(:symbol) # get all companies

  # Get the ave %chg per symbol throughout the year
  @ave_chg_per_year = StockPricesMonthly.select('symbol, AVG(percent_change) AS ave_change, "timestamp"')
                                        .where("EXTRACT(YEAR FROM timestamp) = ?", 2023)
                                        .group('symbol, "timestamp"')
                                        .where(symbol: company)

  if company.present?
    @filtered_symbols = @companies & @monthly_stock_prices.where(symbol: company).pluck(:symbol)
  else
    @filtered_symbols = @companies
    @ave_chg_per_year = StockPricesMonthly.select('symbol, AVG(percent_change) AS ave_change, "timestamp"')
                                          .where("EXTRACT(YEAR FROM timestamp) = ?", 2023)
                                          .group('symbol, "timestamp"')
  end

  # Data for column chart
  @data = @filtered_symbols.map do |filtered_symbol|
    { name: filtered_symbol, data: @monthly_stock_prices.where(symbol: filtered_symbol).pluck(:year_month, :ytd).to_h }
  end


  # Data for the line chart
  @line_chart_data = @ave_chg_per_year.group_by(&:symbol).transform_values do |rows|
    rows.map { |row| [row.timestamp.to_date, row.ave_change] }
  end


  @series_data = @line_chart_data.map { |symbol, values| { name: symbol, data: values } }
end


end




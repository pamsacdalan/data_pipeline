module HomeHelper
    def logo_filename_for_symbol(symbol)
        case symbol
        when 'MSFT'
          'msft.png'
        when 'AAPL'
          'aapl.png'
        when 'TSLA'
          'tsla.png'
        when 'GOOGL'
            'googl.png'
        when 'AMZN'
            'amzn.png'
        when 'JPM'
            'jpm.jpg'
        when 'JNJ'
            'jnj.jpg'
        when 'PG'
            'pg.png'
        when 'V'
            'visa.jpg'
        when 'KO'
            'ko.jpg'
        else
          nil
        end
    end
end

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
        when 'GLO'
            'glo.png'
        when 'SM'
            'sm.png'
        when 'UBP'
            'ubp.jpg'
        when 'TEL'
            'tel.png'
        when 'AAA'
            'aaa.jpg'
        else
          nil
        end
    end
end

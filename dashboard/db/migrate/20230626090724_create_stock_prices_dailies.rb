class CreateStockPricesDailies < ActiveRecord::Migration[7.0]
  def change
    create_table :stock_prices_dailies do |t|
      t.datetime :timestamp
      t.text :symbol
      t.decimal :open
      t.decimal :high
      t.decimal :low
      t.decimal :close
      t.bigint :volume

      t.timestamps
    end
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_06_26_091928) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "my_table", id: :serial, force: :cascade do |t|
    t.string "name"
  end

  create_table "stock_prices_dailies", force: :cascade do |t|
    t.datetime "timestamp"
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_prices_daily", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.decimal "average_price"
    t.decimal "previous_value"
    t.virtual "percent_change", type: :decimal, as: "round((((open - previous_value) / previous_value) * (100)::numeric), 3)", stored: true
    t.virtual "change", type: :decimal, as: "round((open - previous_value), 3)", stored: true
  end

  create_table "stock_prices_intraday", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
  end

  create_table "stock_prices_intradays", force: :cascade do |t|
    t.datetime "timestamp"
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_prices_monthlies", force: :cascade do |t|
    t.datetime "timestamp"
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_prices_monthly", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.decimal "average_price"
    t.decimal "previous_value"
    t.virtual "percent_change", type: :decimal, as: "round((((open - previous_value) / previous_value) * (100)::numeric), 3)", stored: true
    t.virtual "change", type: :decimal, as: "round((open - previous_value), 3)", stored: true
  end

  create_table "stock_prices_weeklies", force: :cascade do |t|
    t.datetime "timestamp"
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_prices_weekly", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.decimal "average_price"
    t.decimal "previous_value"
    t.virtual "percent_change", type: :decimal, as: "round((((open - previous_value) / previous_value) * (100)::numeric), 3)", stored: true
    t.virtual "change", type: :decimal, as: "round((open - previous_value), 3)", stored: true
  end

  create_table "test_daily_neil", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.decimal "average_price"
  end

  create_table "test_intraday_with_computation", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
    t.virtual "average_price", type: :decimal, as: "round(((((open + high) + low) + close) / (4)::numeric), 2)", stored: true
  end

  create_table "test_stock_prices_intraday_adrian", id: false, force: :cascade do |t|
    t.datetime "timestamp", precision: nil
    t.text "symbol"
    t.decimal "open"
    t.decimal "high"
    t.decimal "low"
    t.decimal "close"
    t.bigint "volume"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

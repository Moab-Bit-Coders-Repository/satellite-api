# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_11_18_071826) do

  create_table "invoices", force: :cascade do |t|
    t.string "lid"
    t.string "invoice", limit: 1024
    t.datetime "paid_at"
    t.datetime "created_at"
    t.integer "order_id"
    t.index ["lid"], name: "index_invoices_on_lid", unique: true
    t.index ["order_id"], name: "index_invoices_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "bid"
    t.integer "message_size"
    t.float "bid_per_byte"
    t.string "message_digest", limit: 64
    t.integer "status"
    t.string "uuid", limit: 36
    t.datetime "created_at"
    t.datetime "cancelled_at"
    t.datetime "upload_started_at"
    t.datetime "upload_ended_at"
    t.index ["bid_per_byte"], name: "index_orders_on_bid_per_byte"
    t.index ["uuid"], name: "index_orders_on_uuid", unique: true
  end

end

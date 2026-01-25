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

ActiveRecord::Schema[8.1].define(version: 2025_12_02_084144) do
  create_table "days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_days_on_event_id"
  end

  create_table "event_favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_event_favorites_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_favorites_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_favorites_on_user_id"
  end

  create_table "event_name_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_event_name_tags_on_name", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "event_key", limit: 50, null: false
    t.integer "event_name_tag_id", null: false
    t.boolean "is_published", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_key"], name: "index_events_on_event_key", unique: true
    t.index ["event_name_tag_id"], name: "index_events_on_event_name_tag_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "performances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_id"
    t.integer "duration"
    t.time "end_time"
    t.integer "performer_id", null: false
    t.integer "stage_id"
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.index ["day_id"], name: "index_performances_on_day_id"
    t.index ["performer_id"], name: "index_performances_on_performer_id"
    t.index ["stage_id"], name: "index_performances_on_stage_id"
  end

  create_table "performer_favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "performer_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["performer_id"], name: "index_performer_favorites_on_performer_id"
    t.index ["user_id", "performer_id"], name: "index_performer_favorites_on_user_id_and_performer_id", unique: true
    t.index ["user_id"], name: "index_performer_favorites_on_user_id"
  end

  create_table "performer_name_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_performer_name_tags_on_name", unique: true
  end

  create_table "performers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "event_id", null: false
    t.integer "performer_name_tag_id", null: false
    t.datetime "updated_at", null: false
    t.string "website_url", limit: 50
    t.index ["event_id"], name: "index_performers_on_event_id"
    t.index ["performer_name_tag_id"], name: "index_performers_on_performer_name_tag_id"
  end

  create_table "stage_name_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_stage_name_tags_on_name", unique: true
  end

  create_table "stages", force: :cascade do |t|
    t.string "address", limit: 50
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "event_id", null: false
    t.integer "position", null: false
    t.integer "stage_name_tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_stages_on_event_id"
    t.index ["stage_name_tag_id"], name: "index_stages_on_stage_name_tag_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", limit: 50, default: "", null: false
    t.string "provider", limit: 50, default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid", limit: 255, default: "", null: false
    t.datetime "updated_at", null: false
    t.string "username", limit: 50, default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "days", "events"
  add_foreign_key "event_favorites", "events"
  add_foreign_key "event_favorites", "users"
  add_foreign_key "events", "event_name_tags"
  add_foreign_key "events", "users"
  add_foreign_key "performances", "days"
  add_foreign_key "performances", "performers"
  add_foreign_key "performances", "stages"
  add_foreign_key "performer_favorites", "performers"
  add_foreign_key "performer_favorites", "users"
  add_foreign_key "performers", "events"
  add_foreign_key "performers", "performer_name_tags"
  add_foreign_key "stages", "events"
  add_foreign_key "stages", "stage_name_tags"
end

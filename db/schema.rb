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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_000009) do
  create_table "articles", force: :cascade do |t|
    t.string "author"
    t.text "body"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "hero_color"
    t.date "published_on"
    t.integer "read_minutes"
    t.text "summary"
    t.string "tag"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_articles_on_category"
  end

  create_table "checkins", force: :cascade do |t|
    t.date "checkin_date", null: false
    t.datetime "created_at", null: false
    t.integer "diastolic"
    t.integer "energy"
    t.integer "mood"
    t.text "notes"
    t.integer "resting_hr"
    t.decimal "sleep_hours", precision: 4, scale: 1
    t.integer "stress"
    t.integer "systolic"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "water_oz"
    t.decimal "weight", precision: 6, scale: 2
    t.index ["user_id", "checkin_date"], name: "index_checkins_on_user_id_and_checkin_date", unique: true
    t.index ["user_id"], name: "index_checkins_on_user_id"
  end

  create_table "health_profiles", force: :cascade do |t|
    t.string "activity_level"
    t.text "allergies"
    t.string "blood_type"
    t.string "coach_name"
    t.text "conditions"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "dietary_preference"
    t.string "emergency_contact"
    t.decimal "goal_weight", precision: 6, scale: 2
    t.decimal "height_in", precision: 5, scale: 2
    t.string "primary_goal"
    t.string "sex"
    t.decimal "starting_weight", precision: 6, scale: 2
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_health_profiles_on_user_id", unique: true
  end

  create_table "meal_entries", force: :cascade do |t|
    t.integer "calories"
    t.integer "carbs_g"
    t.date "consumed_on", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "fat_g"
    t.string "meal_type"
    t.string "name"
    t.integer "protein_g"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "consumed_on"], name: "index_meal_entries_on_user_id_and_consumed_on"
    t.index ["user_id"], name: "index_meal_entries_on_user_id"
  end

  create_table "routine_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "day_label"
    t.string "notes"
    t.integer "position"
    t.integer "routine_id", null: false
    t.datetime "updated_at", null: false
    t.integer "workout_id", null: false
    t.index ["routine_id"], name: "index_routine_items_on_routine_id"
    t.index ["workout_id"], name: "index_routine_items_on_workout_id"
  end

  create_table "routines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days_per_week"
    t.text "description"
    t.integer "duration_weeks"
    t.string "focus"
    t.string "goal"
    t.string "level"
    t.string "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "workout_logs", force: :cascade do |t|
    t.string "activity"
    t.integer "calories_burned"
    t.datetime "created_at", null: false
    t.integer "duration_min"
    t.string "intensity"
    t.text "notes"
    t.date "performed_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "workout_id"
    t.index ["user_id", "performed_on"], name: "index_workout_logs_on_user_id_and_performed_on"
    t.index ["user_id"], name: "index_workout_logs_on_user_id"
    t.index ["workout_id"], name: "index_workout_logs_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.integer "calories_est"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_min"
    t.string "equipment"
    t.string "focus_area"
    t.string "instructor"
    t.string "level"
    t.string "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index ["category"], name: "index_workouts_on_category"
  end

  add_foreign_key "checkins", "users"
  add_foreign_key "health_profiles", "users"
  add_foreign_key "meal_entries", "users"
  add_foreign_key "routine_items", "routines"
  add_foreign_key "routine_items", "workouts"
  add_foreign_key "workout_logs", "users"
  add_foreign_key "workout_logs", "workouts"
end

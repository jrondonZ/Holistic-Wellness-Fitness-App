class CreateCheckins < ActiveRecord::Migration[8.1]
  def change
    create_table :checkins do |t|
      t.references :user, null: false, foreign_key: true
      t.date    :checkin_date, null: false
      t.integer :mood
      t.integer :energy
      t.integer :stress
      t.decimal :sleep_hours, precision: 4, scale: 1
      t.integer :water_oz
      t.decimal :weight, precision: 6, scale: 2
      t.integer :resting_hr
      t.integer :systolic
      t.integer :diastolic
      t.text    :notes

      t.timestamps
    end

    add_index :checkins, [ :user_id, :checkin_date ], unique: true
  end
end

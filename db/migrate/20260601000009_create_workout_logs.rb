class CreateWorkoutLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :workout_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workout, foreign_key: true
      t.date    :performed_on, null: false
      t.string  :activity
      t.integer :duration_min
      t.string  :intensity
      t.integer :calories_burned
      t.text    :notes

      t.timestamps
    end

    add_index :workout_logs, [ :user_id, :performed_on ]
  end
end

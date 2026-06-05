class CreateRoutines < ActiveRecord::Migration[8.1]
  def change
    create_table :routines do |t|
      t.string  :title, null: false
      t.string  :goal
      t.string  :level
      t.string  :focus
      t.integer :days_per_week
      t.integer :duration_weeks
      t.string  :summary
      t.text    :description

      t.timestamps
    end
  end
end

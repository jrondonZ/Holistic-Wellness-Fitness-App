class CreateWorkouts < ActiveRecord::Migration[8.1]
  def change
    create_table :workouts do |t|
      t.string  :title, null: false
      t.string  :category
      t.string  :level
      t.integer :duration_min
      t.integer :calories_est
      t.string  :equipment
      t.string  :focus_area
      t.string  :instructor
      t.string  :video_url
      t.string  :summary
      t.text    :description

      t.timestamps
    end

    add_index :workouts, :category
  end
end

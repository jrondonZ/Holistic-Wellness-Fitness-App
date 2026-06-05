class CreateRoutineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_items do |t|
      t.references :routine, null: false, foreign_key: true
      t.references :workout, null: false, foreign_key: true
      t.integer :position
      t.string  :day_label
      t.string  :notes

      t.timestamps
    end
  end
end

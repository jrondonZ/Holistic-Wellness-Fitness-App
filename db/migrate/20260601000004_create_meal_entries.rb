class CreateMealEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date    :consumed_on, null: false
      t.string  :meal_type
      t.string  :name
      t.text    :description
      t.integer :calories
      t.integer :protein_g
      t.integer :carbs_g
      t.integer :fat_g

      t.timestamps
    end

    add_index :meal_entries, [ :user_id, :consumed_on ]
  end
end

class CreateCareAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :care_assignments do |t|
      t.references :member,   null: false, foreign_key: { to_table: :users }
      t.references :provider, null: false, foreign_key: { to_table: :users }
      t.string  :specialty
      t.boolean :primary, null: false, default: false

      t.timestamps
    end

    add_index :care_assignments, [ :member_id, :provider_id ], unique: true
  end
end

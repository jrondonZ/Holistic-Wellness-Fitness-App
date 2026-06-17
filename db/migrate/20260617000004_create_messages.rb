class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      # The member whose conversation this belongs to (a thread is always
      # between one member and the clinic/admin team).
      t.references :member, null: false, foreign_key: { to_table: :users }
      # The author of this individual message (the member or an admin).
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text     :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :messages, [ :member_id, :created_at ]
  end
end

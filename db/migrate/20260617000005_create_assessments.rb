class CreateAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.references :member, null: false, foreign_key: { to_table: :users }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string  :title, null: false
      t.string  :category
      t.string  :severity, null: false, default: "info"
      t.string  :status, null: false, default: "open"
      t.text    :summary
      t.text    :recommendations

      t.timestamps
    end

    add_index :assessments, [ :member_id, :created_at ]
  end
end

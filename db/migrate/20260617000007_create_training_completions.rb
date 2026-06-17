class CreateTrainingCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :training_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :training_module, null: false, foreign_key: true
      t.datetime :completed_at
      t.string   :signature
      t.integer  :score
      t.boolean  :acknowledged, null: false, default: false

      t.timestamps
    end

    add_index :training_completions, [ :user_id, :training_module_id ], unique: true, name: "index_training_completions_on_user_and_module"
  end
end

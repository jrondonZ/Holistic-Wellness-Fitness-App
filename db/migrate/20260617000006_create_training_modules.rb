class CreateTrainingModules < ActiveRecord::Migration[8.1]
  def change
    create_table :training_modules do |t|
      t.string  :slug, null: false
      t.string  :title, null: false
      t.string  :version
      t.text    :summary
      t.text    :body
      t.integer :minutes, default: 10
      t.boolean :required, null: false, default: true
      t.integer :position, default: 0
      t.text    :quiz # JSON-encoded knowledge-check questions

      t.timestamps
    end

    add_index :training_modules, :slug, unique: true
  end
end

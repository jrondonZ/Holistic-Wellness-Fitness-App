class AddTopicToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :topic, :string
  end
end

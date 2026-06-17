class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "member"
    add_column :users, :phone, :string
    add_column :users, :title, :string
    add_column :users, :bio, :text
    add_index  :users, :role
  end
end

class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.string  :category
      t.string  :tagline
      t.text    :description
      t.integer :duration_min, default: 60
      t.integer :price_cents
      t.string  :provider_name
      t.string  :color
      t.string  :icon
      t.boolean :active, null: false, default: true
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :services, :slug, unique: true
    add_index :services, :category
  end
end

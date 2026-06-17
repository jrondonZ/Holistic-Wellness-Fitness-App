class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.datetime :scheduled_at, null: false
      t.integer  :duration_min, default: 60
      t.string   :status, null: false, default: "requested"
      t.string   :mode, null: false, default: "in_person"
      t.string   :location
      t.string   :meeting_url
      t.text     :reason
      t.text     :admin_notes
      t.datetime :confirmed_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :appointments, [ :user_id, :scheduled_at ]
    add_index :appointments, :status
    add_index :appointments, :scheduled_at
  end
end

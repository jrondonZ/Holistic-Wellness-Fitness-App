class CreateHealthProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :health_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.date    :date_of_birth
      t.string  :sex
      t.decimal :height_in, precision: 5, scale: 2
      t.decimal :starting_weight, precision: 6, scale: 2
      t.decimal :goal_weight, precision: 6, scale: 2
      t.string  :activity_level
      t.string  :dietary_preference
      t.string  :blood_type
      t.string  :primary_goal
      t.string  :coach_name
      t.string  :emergency_contact
      t.text    :allergies
      t.text    :conditions

      t.timestamps
    end
  end
end

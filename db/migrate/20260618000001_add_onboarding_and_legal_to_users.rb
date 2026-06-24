class AddOnboardingAndLegalToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarded_at, :datetime
    add_column :users, :terms_accepted_at, :datetime
    add_column :users, :privacy_accepted_at, :datetime
    add_column :users, :accepted_terms_version, :string
    add_column :users, :accepted_privacy_version, :string
  end
end

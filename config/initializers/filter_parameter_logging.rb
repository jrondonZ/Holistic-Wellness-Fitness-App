# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  # Credentials & identifiers
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # Protected health information (PHI) — keep the member's health data out of logs.
  # Partial matching means e.g. :weight also covers goal_weight/starting_weight, and
  # :body covers secure-message bodies that may discuss health.
  :date_of_birth, :dob, :phone, :weight, :height_in, :systolic, :diastolic,
  :resting_hr, :blood_pressure, :mood, :energy, :stress, :sleep_hours, :water_oz,
  :body, :note, :notes, :description, :diagnosis, :medication, :allergies,
  :medical, :health, :insurance
]

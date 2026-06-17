class ChangeAppointmentDurationDefault < ActiveRecord::Migration[8.1]
  def change
    # Remove the fixed default so new bookings inherit their service's duration.
    change_column_default :appointments, :duration_min, from: 60, to: nil
  end
end

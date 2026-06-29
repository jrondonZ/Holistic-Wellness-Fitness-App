# Tamper-evident access trail for protected health information (PHI).
#
# Every meaningful read or write of a member's health record is recorded here:
# who did it (actor), whose record it touched (subject), what action, against
# which resource, and from where (IP / user agent). This "access log" is a core
# expectation of clinical portals like Epic MyChart and underpins HIPAA's audit
# controls (45 CFR §164.312(b)).
class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :actor,   null: true, foreign_key: { to_table: :users }  # who performed the action
      t.references :subject, null: true, foreign_key: { to_table: :users }  # whose record was accessed
      t.string  :action,        null: false                                  # view / create / update / destroy / login / export …
      t.string  :resource_type                                               # model class touched
      t.integer :resource_id                                                 # its id
      t.string  :ip_address
      t.string  :user_agent
      t.json    :metadata                                                    # small, non-PHI context (e.g. fields changed)
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [ :subject_id, :created_at ]
    add_index :audit_logs, [ :actor_id, :created_at ]
    add_index :audit_logs, [ :action, :created_at ]
  end
end

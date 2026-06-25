# Links a member to a provider (staff). The owner manages these — members can
# only message providers they're assigned to.
class CareAssignment < ApplicationRecord
  belongs_to :member,   class_name: "User"
  belongs_to :provider, class_name: "User"

  validates :member_id, uniqueness: { scope: :provider_id, message: "is already assigned to this provider" }
  validate  :provider_is_staff
  validate  :member_is_member

  scope :primary_first, -> { order(primary: :desc) }

  private

  def provider_is_staff
    errors.add(:provider, "must be a staff member") unless provider&.staff?
  end

  def member_is_member
    errors.add(:member, "must be a member") unless member&.member?
  end
end

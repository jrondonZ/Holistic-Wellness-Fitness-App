# Versioned legal documents. Bump a version string to re-prompt every user to
# re-accept the corresponding document on their next visit.
module Legal
  TERMS_VERSION   = "2026-06-18"
  PRIVACY_VERSION = "2026-06-18"
  EFFECTIVE_DATE  = "June 18, 2026"
  COMPANY         = "Holistic Wellness Fitness LLC"
  CONTACT_EMAIL   = "info@holisticwellnessandfitness.com"
  ADDRESS         = "177 State Street, Meriden, CT 06450"

  module_function

  def terms_version   = TERMS_VERSION
  def privacy_version = PRIVACY_VERSION
end

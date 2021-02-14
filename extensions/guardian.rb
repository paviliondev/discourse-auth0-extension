module GuardianAuth0Extension
  def can_invite_to_forum?(groups = nil)
    return true if authenticated? && is_admin? && SiteSetting.auth0_bulk_invites
    super
  end
end
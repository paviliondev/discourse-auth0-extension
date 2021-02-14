module UsersControllerAuth0Extension
  def perform_account_activation
    super

    if SiteSetting.auth0_extension_enabled
      if @user.active
        @auth0 = ::Auth0::Request.new
          
        if @auth0.ready?
          response = @auth0.get_users_id(email: @user.email)
          if response.kind_of?(Array) && !response[0].nil? && response[0].has_key?('user_id')
            response = @auth0.validate_email_with_user_id(user_id: CGI.escape(response[0]['user_id']))
          else
            Rails.logger.warn("Problem finding this user's email in Auth0: #{@user.email}")
          end
        end
      end
    end
  end
end

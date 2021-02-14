# frozen_string_literal: true

# name: discourse-auth0-extension
# about: Extends Auth0 functionality in Discourse
# version: 0.0.1
# authors: Pavilion
# url: https://github.com/paviliondev/discourse-auth0-extension

enabled_site_setting :auth0_extension_enabled
add_admin_route 'auth0_extension.title', 'auth0-extension'
register_asset 'stylesheets/common/auth0_extension.scss'

module ::ODICStrategyExtension
  def authorize_params
    super.tap do |params|
      if request.cookies["auth0_silent"]
        params[:prompt] = "none"
        params[:scope] = "openid profile email"
      end
    end
  end
end

on(:after_plugin_activation) do
  if Discourse.plugins.any? { |p| p.name == 'discourse-openid-connect' }
    OmniAuth::Strategies::OpenIDConnect.prepend ODICStrategyExtension
  end
end

after_initialize do
  %w{
    ../lib/auth0/engine.rb
    ../lib/auth0/log.rb
    ../lib/auth0/request.rb
    ../app/controllers/auth0/admin_controller.rb
    ../app/serializers/auth0/log_serializer.rb
    ../jobs/regular/handle_auth0_invites.rb
    ../mailers/auth0_mailer.rb
    ../extensions/invites_controller.rb
    ../extensions/users_controller.rb
    ../extensions/guardian.rb
    ../config/routes.rb
  }.each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  ::UsersController.prepend UsersControllerAuth0Extension
  ::InvitesController.prepend InvitesControllerAuth0Extension
  ::Guardian.prepend GuardianAuth0Extension
  
  add_model_callback(:application_controller, :before_action) do
    if current_user && cookies[:auth0_silent]
      cookies.delete(:auth0_silent)
    elsif !current_user
      attempt_auth0_silent_login if SiteSetting.auth0_silent_login &&
        !SiteSetting.enable_local_logins &&
        Discourse.enabled_authenticators.length == 1 &&
        Discourse.enabled_authenticators.first.name == 'oidc' &&
        !cookies[:auth0_silent]
    end
  end
  
  add_to_class(:application_controller, :attempt_auth0_silent_login) do    
    cookies[:destination_url] = destination_url
    cookies[:auth0_silent] = true
    redirect_to path("/auth/#{Discourse.enabled_authenticators.first.name}")
  end
end

class Auth0Mailer < ActionMailer::Base
  include Email::BuildEmailHelper

  def invite_email(to_address, inviter_name, ticket_url)
    build_email(to_address,
      template: 'invite_forum_mailer',
      inviter_name: inviter_name,
      site_domain_name: Discourse.current_hostname,
      invite_link: ticket_url,
      site_description: SiteSetting.site_description,
      site_title: SiteSetting.title
    )
  end
end
# frozen_string_literal: true

module Jobs
  class HandleAuth0Invites < ::Jobs::Base    
    def execute(args)
      %i{
        user_id
        auth0_job_id
        count
        invite_emails
      }.each do |key|
        raise Discourse::InvalidParameters.new(key) if args[key].blank?
      end
      
      @admin_user = User.find(args[:user_id])
      @auth0 = ::Auth0::Request.new
      count = args[:count].to_i
      
      if @auth0.ready? && (response = @auth0.job_status(args[:auth0_job_id]))
        job_status = response['status']
                
        if job_status == "completed"
          new_users = @auth0.users_by_email(args[:invite_emails])
          invited_emails = []
          
          if new_users.any?           
            new_users.each do |user|
              sleep(15.seconds)
              result = get_password_change_ticket(user)
              
              if !result[:error]
                message = Auth0Mailer.invite_email(user['email'], @admin_user.name, result['ticket']) 
                Email::Sender.new(message, :invite).send
                invited_emails.push(user['email'])
              end
            end
          end
                    
          failed_emails = args[:invite_emails] - invited_emails
          create_report(job_status, invited_emails, failed_emails)
        elsif count <= 5
          time_left = response['time_left_seconds'].present? ? response['time_left_seconds'].to_i.seconds : 1.minutes 
          next_job_time = Time.now + time_left
          
          ::Jobs.enqueue_at(next_job_time, :handle_auth0_invites,
            auth0_job_id: response['id'],
            count: count + 1,
            invite_emails: args[:invite_emails],
            user_id: args[:user_id]
          )
        else
          create_report('Auth0 job failed', [], args[:invite_emails])
        end
      else
        create_report('Failed to connect to Auth0', [], args[:invite_emails])
      end
    end
    
    def create_report(job_status, invited_emails=[], failed_emails=[])
      SystemMessage.create_from_system_user(
        @admin_user,
        :auth0_invite_report,
        job_status: job_status,
        invited_users: invited_emails.join(','),
        failed_users: failed_emails.join(',')
      )
    end
    
    def get_password_change_ticket(user)
      result = @auth0.password_change_ticket(user['user_id'],
        result_url: Discourse.base_url + "/auth/oauth2_basic"
      )
    end
  end
end
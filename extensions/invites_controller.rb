module InvitesControllerAuth0Extension
  def upload_csv
    if SiteSetting.auth0_bulk_invites
      require 'csv'

      guardian.ensure_can_bulk_invite_to_forum!(current_user)

      hijack do
        begin
          file = params[:file] || params[:files].first

          count = 0
          invites = []
          
          CSV.foreach(file.tempfile) do |row|
            count += 1
            
            if row[0].present?
              user = {
                email: row[0],
                email_verified: false
              }
              
              if (groups = row[1]).present?
                user[:user_metadata] = {
                  discourse: {
                    group: groups.gsub(';',',')
                  }
                }
              end
              
              invites.push(user)
            end
          end
                    
          if invites.present?
            auth0 = Auth0::Request.new
            result = auth0.ready? ? auth0.import_users(invites) : { error: true }
                        
            if result['status'] == 'pending'
              Jobs.enqueue_at(Time.now + 15.seconds, :handle_auth0_invites,
                auth0_job_id: result['id'],
                count: 1,
                invite_emails: invites.map { |u| u[:email] },
                user_id: current_user.id
              )     
              render json: success_json
            else
              render_bulk_invite_error
            end
          else
            render_bulk_invite_error
          end
        rescue
          render_bulk_invite_error
        end
      end
    else
      super
    end 
  end
  
  def render_bulk_invite_error
    render json: failed_json.merge(errors: [I18n.t("bulk_invite.error")]), status: 422
  end

  def perform_accept_invitation
    if SiteSetting.auth0_extension_enabled
      @auth0 = ::Auth0::Request.new

      if @auth0.ready?
        response = @auth0.create_user(email:
          params[:email],
          name: params[:name],
          password: params[:password]
        )
      end

      if !response.has_key?(:error)
        super
      else
        render json: { success: false, message: response[:message]}
      end
    else
      super
    end
  end
end
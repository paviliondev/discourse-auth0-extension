require 'net/http/post/multipart'

class Auth0::Request
  
  attr_accessor :domain,
                :client_id,
                :client_secret

  AUTH0_CONNECTION = "Username-Password-Authentication"
  
  def initialize
    @domain = SiteSetting.auth0_domain
    @client_id = SiteSetting.auth0_client_id
    @client_secret = SiteSetting.auth0_client_secret
    
    return nil if @domain.blank? ||
      @client_id.blank? ||
      @client_secret.blank?
    
    if (token = get_saved_token)
      @token = token
    else
      result = request_token
      
      if result.present? && result["access_token"]
        log("connected successfully to auth0")
        @token = result["access_token"]
        save_token(@token, result['expires_in'])
      else
        log("failed to connect to auth0")
        result
      end
    end
  end
  
  def ready?
    @token.present?
  end
  
  def request_token
    body = {
      grant_type: 'client_credentials',
      client_id: @client_id,
      client_secret: @client_secret,
      audience: URI("https://#{@domain}/api/v2/")
    }
    request("/oauth/token", body: body, class: Net::HTTP::Post)
  end
  
  def import_users(users)
    connection_id = SiteSetting.auth0_invites_connection_id
    
    return { 'error' => "No connection id" } if connection_id.blank?
    
    body = {
      users: UploadIO.new(StringIO.new(users.to_json), "application/json", "users.json"),
      connection_id: connection_id,
      send_completion_email: true
    }
    
    log("importing #{users.length} users into auth0")
        
    result = request("/api/v2/jobs/users-imports",
      content_type: "multipart/form-data",
      body: body
    )
        
    if result['error']
      log("error importing users into auth0: #{result['error']}")
      { 'error' => result['message'] }
    else
      log("successfully imported users into auth0: #{users.map{ |u| u[:email] }.join(',')}")
      result
    end
  end
  
  def job_status(job_id)
    request("/api/v2/jobs/#{job_id}")
  end
  
  def users_by_email(emails=[])
    query = {
      fields: 'user_id,email',
      include_fields: true,
      q: emails.map{ |email| "email:#{email.to_s}" }.join(' OR '),
      search_engine: 'v3'
    }
    request("/api/v2/users", query: query)
  end

  def get_users_id(email:)
    body = {
      connection: AUTH0_CONNECTION
    }
    request("/api/v2/users?q=email:\"#{CGI::escape(email)}\"", body: body, class: Net::HTTP::Get)
  end

  def validate_email_with_user_id(user_id:)
    body = {
      connection: AUTH0_CONNECTION,
      email_verified: true
    }
    request("/api/v2/users/#{user_id}", body: body, class: Net::HTTP::Patch)
  end

  def create_user(email:, name: , password:)
    body = {
      email: email,
      name: name,
      password: password,
      connection: AUTH0_CONNECTION
    }
    request("/api/v2/users", body: body, class: Net::HTTP::Post)
  end
  
  def password_change_ticket(user_id, mark_email_as_verified: true, result_url: Discourse.base_url)
    body = {
      user_id: user_id,
      mark_email_as_verified: mark_email_as_verified,
      result_url: result_url
    }
    request("/api/v2/tickets/password-change", body: body, class: Net::HTTP::Post)
  end
  
  def request(endpoint, opts={})
    url = URI("https://#{@domain}#{endpoint}")
    url.query = URI.encode_www_form(opts[:query]) if opts[:query].present?
        
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    content_type = opts[:content_type] || 'application/x-www-form-urlencoded'
    
    if content_type == 'multipart/form-data'
      request = Net::HTTP::Post::Multipart.new url.path, opts[:body]
      request.add_field("Authorization", "Bearer #{@token}") if @token.present?
    else
      request_class = opts[:class] || Net::HTTP::Get
      request = request_class.new url
      request.body = URI.encode_www_form(opts[:body]) if opts[:body].present?
      request["content-type"] = content_type
      request["authorization"] = "Bearer #{@token}" if @token.present?
    end
        
    response = http.request(request)
            
    if response.kind_of? Net::HTTPSuccess
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { error: "request failed"}
      end
    else
      begin
        response_message = JSON.parse(response.body)['message']
        { error: "request failed", message: response_message}
      rescue JSON::ParserError
        { error: "request failed"}
      end
    end
  end
  
  private
  
  def log(message)
    Auth0::Log.create(message: message)
  end
  
  def save_token(token, expires_in)
    PluginStore.set(Auth0::PLUGIN_NAME, 'auth0-token', {
      token: token,
      expires_at: Time.now + expires_in.to_i.seconds
    })
  end
  
  def get_saved_token
    data = PluginStore.get(Auth0::PLUGIN_NAME, 'auth0-token')
    
    if data.present? && (Time.parse(data['expires_at']) > Time.now + 10.minutes)
      data[:token]
    else
      nil
    end
  end
end
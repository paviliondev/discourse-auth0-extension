class Auth0::AdminController < Admin::AdminController
  def index
    render_serialized(
      Auth0::Log.list(page: params[:page].to_i, filter: params[:filter]),
      Auth0::LogSerializer
    )
  end
end
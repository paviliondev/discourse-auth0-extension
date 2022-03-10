Discourse::Application.routes.append do
  get '/admin/plugins/auth0-extension' => 'auth0/admin#index', constraints: AdminConstraint.new
end
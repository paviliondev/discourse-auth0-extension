Discourse::Application.routes.append do
  get '/admin/plugins/auth0-extension' => 'auth0_extension/admin#index', constraints: AdminConstraint.new
end
module ::Auth0
  class Engine < ::Rails::Engine
    engine_name 'auth0_extension'
    isolate_namespace Auth0
  end
  
  PLUGIN_NAME ||= "discourse-auth0-extension"
end
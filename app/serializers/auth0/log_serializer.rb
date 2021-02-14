class Auth0::LogSerializer < ApplicationSerializer
  attributes :type, :format, :user, :group, :message, :date
end
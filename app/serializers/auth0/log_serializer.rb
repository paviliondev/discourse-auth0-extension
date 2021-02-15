class Auth0::LogSerializer < ApplicationSerializer
  attributes :user, :group, :message, :date
end
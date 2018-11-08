require 'sinatra/base'

module Sinatra
  module URLHelpers

    def callback_url(order_uuid, auth_token)
      "#{CALLBACK_URI_ROOT}/callback/#{order_uuid}/#{auth_token}"
    end

  end
  helpers URLHelpers
end
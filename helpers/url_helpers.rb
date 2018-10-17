require 'sinatra/base'

module Sinatra
  module URLHelpers

    def callback_url(order_id, auth_token)
      "#{CALLBACK_URI_ROOT}/callback/#{order_id}/#{auth_token}"
    end

  end
  helpers URLHelpers
end
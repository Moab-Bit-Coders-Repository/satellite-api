require 'sinatra/base'

module Sinatra
  module URLHelpers

    def callback_url(lightning_invoice_id, auth_token)
      "#{CALLBACK_URI_ROOT}/callback/#{lightning_invoice_id}/#{auth_token}"
    end

  end
  helpers URLHelpers
end
module Sinatra
  module OrderHelpers
    
    def sanitize_uuid_param(uuid)
      # Bad as defined by wikipedia: https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
      bad_chars = [ '/', '\\', '?', '%', '*', ':', '|', '"', '<', '>', '.', ' ' ]
      bad_chars.each do |bad_char|
        uuid.gsub!(bad_char, '_')
      end
      uuid
    end
    
    def fetch_order_by_uuid
      Order.where(uuid: params[:uuid]).first || halt(404, {:message => "Not found", :errors => ["Invalid order id"]}.to_json)
    end
    
    def authorize_order!(order)
      if order.user_auth_token != params[:auth_token]
        halt 401, {:message => "Unauthorized", :errors => ["Invalid authentication token"]}.to_json
      else
        order
      end
    end
    
    def order
      @order ||= authorize_order!(fetch_order_by_uuid)
    end

  end
  helpers OrderHelpers
end

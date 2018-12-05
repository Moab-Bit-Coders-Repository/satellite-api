module Sinatra
  module OrderHelpers
    
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
    
    def order_status_sse(order)
      "event: #{order.status}\n" \
      "data: #{order.to_json(:only => Order::PUBLIC_FIELDS)}\n\n"
    end

  end
  helpers OrderHelpers
end

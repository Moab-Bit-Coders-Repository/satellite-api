require 'sinatra'
require "faraday"
require 'data_mapper'
require 'dm-noisy-failures'
require 'securerandom'

require_relative 'constants'
require_relative 'dm_config'
require_relative './helpers/init'

configure do
  set :raise_errors, false
  set :show_exceptions, :after_handler

  LIGHTNING_HOOK_KEY = hash_hmac('sha256', 'lightning-hook-token', CHARGE_API_TOKEN)
  $lightning_charge = Faraday.new(:url => CHARGE_ROOT)  
end

before do
  content_type :json
end

# XXX DEBUG
get '/info' do
  # call lightning-charge info
  response = $lightning_charge.get '/info'
  response.body
end

# GET /queue
# get snapshot of message queue
get '/queue' do
  Order.all(:fields => Order::PUBLIC_FIELDS, 
            :status.not => [:sent, :cancelled],
            :order => [:created_at.desc]).to_json(:only => Order::PUBLIC_FIELDS)
end

get '/sent_messages' do
  Order.all(:fields => Order::PUBLIC_FIELDS, 
            :status => :sent,
            :order => [:created_at.desc]).to_json(:only => Order::PUBLIC_FIELDS)
end

get '/message/:message_hash' do
  send_file File.join(MESSAGE_STORE_PATH, params[:message_hash])
end

# POST /send
#  
# send a message, along with a bid
# return JSON object with status, order_id, and lightning payment invoice
post '/send' do
  param :bid, Float, required: true, min: MIN_PER_BYTE_BID
  param :message, String, required: true, max_length: MAX_MESSAGE_SIZE

  message_digest = sha256_digest(params[:message])
  order_id = SecureRandom.uuid
  auth_token = hash_hmac('sha256', LIGHTNING_HOOK_KEY, order_id)
  
  # generate Lightning invoice
  response = $lightning_charge.post '/invoice', {
    msatoshi: Integer(params[:bid] * params[:message].size),
    description: LN_INVOICE_DESCRIPTION,
    expiry: LN_INVOICE_EXPIRY, 
    metadata: {id: order_id, msatoshis_per_byte: params[:bid], sha256_message_digest: message_digest.to_s},
    webhook: callback_url(order_id, auth_token)
  }
  
  unless response.status == 201
    halt 400, {:message => "Lightning Charge error", :errors => ["received #{response.status} from charged"]}.to_json
  end

  lightning_invoice = JSON.parse(response.body)

  Order.create(
    :bid => params[:bid],
    :message => params[:message],
    :message_digest => message_digest,
    :status => :pending,
    :orderid => order_id,
    :lightning_invoiceid => lightning_invoice["id"],
    :lightning_invoice => lightning_invoice.to_json,
    :created_at => Time.now
  )
  
  # return lightning invoice
  lightning_invoice.to_json
end

delete '/cancel/:order_id/:auth_token' do
  unless hash_hmac('sha256', LIGHTNING_HOOK_KEY, params[:order_id]) == params[:auth_token]
    halt 400, {:message => "Invalid authentication token", :errors => ["Invalid authentication token in callback"]}.to_json
  end
  
  unless order = Order.first(:orderid => params[:order_id])
    halt 400, {:message => "Invalid order id", :errors => ["Invalid order #{order_id}"]}.to_json
  end

  unless [:pending, :paid].include?(order.status)
    halt 400, {:message => "Cannot cancel order", :errors => ["Order already #{order.status}"]}.to_json
  end

  order.update(:status => :cancelled)

  {:message => "order cancelled"}.to_json
end

# invoice paid callback from charged
post '/callback/:order_id/:auth_token' do
  unless hash_hmac('sha256', LIGHTNING_HOOK_KEY, params[:order_id]) == params[:auth_token]
    halt 400, {:message => "Invalid authentication token", :errors => ["Invalid authentication token in callback"]}.to_json
  end
  
  unless order = Order.first(:orderid => params[:order_id])
    halt 400, {:message => "Invalid order id", :errors => ["Invalid order #{order_id}"]}.to_json
  end

  unless order.status == :pending
    halt 400, {:message => "Payment problem", :errors => ["Order already #{order.status}"]}.to_json
  end

  order.update(:status => :paid)
  
  {:message => "order paid"}.to_json
end

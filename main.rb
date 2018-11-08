require 'sinatra'
require "faraday"
require 'data_mapper'
require 'dm-noisy-failures'
require 'securerandom'
require 'openssl'

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
  send_file File.join(SENT_MESSAGE_STORE_PATH, params[:message_hash]), :disposition => 'attachment'
end

# POST /order
#  
# send a message, along with a bid
# return JSON object with status, uuid, and lightning payment invoice
post '/order' do
  param :bid, Float, required: true, min: MIN_PER_BYTE_BID

  # process the upload
  unless params[:file]
    halt 400, {:message => "Message upload problem", :errors => ["No file selected"]}.to_json
  end
  unless tmpfile = params[:file][:tempfile]
    halt 400, {:message => "Message upload problem", :errors => ["No tempfile received"]}.to_json
  end
  unless name = params[:file][:filename]
    halt 400, {:message => "Message upload problem", :errors => ["Filename missing"]}.to_json
  end

  order = Order.new(:bid => params[:bid], :uuid => SecureRandom.uuid)
  message_file = File.new(order.message_path, "wb")
  message_size = 0
  sha256 = OpenSSL::Digest::SHA256.new
  while block = tmpfile.read(65536)
    message_size += block.size
    if message_size > MAX_MESSAGE_SIZE
      halt 413, {:message => "Message upload problem", :errors => ["Message size exceeds max size #{MAX_MESSAGE_SIZE}"]}.to_json
    end
    sha256 << block
    message_file.write(block)
  end
  message_file.close()

  order.message_size = message_size
  order.message_digest = sha256.to_s
  auth_token = hash_hmac('sha256', LIGHTNING_HOOK_KEY, order.uuid)
  
  # generate Lightning invoice
  charged_response = $lightning_charge.post '/invoice', {
    msatoshi: Integer(order.bid * order.message_size),
    description: LN_INVOICE_DESCRIPTION,
    expiry: LN_INVOICE_EXPIRY, 
    metadata: {uuid: order.uuid, msatoshis_per_byte: order.bid, sha256_message_digest: order.message_digest},
    webhook: callback_url(order.uuid, auth_token)
  }
  
  unless charged_response.status == 201
    halt 400, {:message => "Lightning Charge error", :errors => ["received #{response.status} from charged"]}.to_json
  end

  lightning_invoice_json = charged_response.body
  lightning_invoice = JSON.parse(lightning_invoice_json)

  order.status = :pending
  order.lightning_invoiceid = lightning_invoice["id"]
  order.lightning_invoice = lightning_invoice_json
  order.created_at = Time.now
  order.save
  
  # return lightning invoice
  lightning_invoice_json
end

delete '/cancel/:uuid/:auth_token' do
  unless hash_hmac('sha256', LIGHTNING_HOOK_KEY, params[:uuid]) == params[:auth_token]
    halt 400, {:message => "Invalid authentication token", :errors => ["Invalid authentication token in callback"]}.to_json
  end
  
  unless order = Order.first(:uuid => params[:uuid])
    halt 400, {:message => "Invalid order id", :errors => ["Invalid order #{params[:uuid]}"]}.to_json
  end

  unless [:pending, :paid].include?(order.status)
    halt 400, {:message => "Cannot cancel order", :errors => ["Order already #{order.status}"]}.to_json
  end

  order.update(:status => :cancelled)

  {:message => "order cancelled"}.to_json
end

# invoice paid callback from charged
post '/callback/:uuid/:auth_token' do
  unless hash_hmac('sha256', LIGHTNING_HOOK_KEY, params[:uuid]) == params[:auth_token]
    halt 400, {:message => "Invalid authentication token", :errors => ["Invalid authentication token in callback"]}.to_json
  end
  
  unless order = Order.first(:uuid => params[:uuid])
    halt 400, {:message => "Invalid order uuid", :errors => ["Invalid order #{params[:uuid]}"]}.to_json
  end

  unless order.status == :pending
    halt 400, {:message => "Payment problem", :errors => ["Order already #{order.status}"]}.to_json
  end

  order.update(:status => :paid)
  
  {:message => "order paid"}.to_json
end

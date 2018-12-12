require 'sinatra'
require "sinatra/activerecord"
require "faraday"
require 'securerandom'
require 'openssl'
require 'time'

require_relative 'constants'
require_relative './models/init'
require_relative 'helpers/init'

configure do
  set :raise_errors, false
  set :show_exceptions, :after_handler

  $lightning_charge = Faraday.new(:url => CHARGE_ROOT)  
end

before do
  content_type :json
end

configure :development do
  get '/info' do
    # call lightning-charge info
    response = $lightning_charge.get '/info'
    response.body
  end
end

# GET /orders/queued
# params: 
#   limit - return top limit orders (optional)
# returns:
#   array of JSON orders sorted by bid-per-byte descending
get '/orders/queued' do
  param :limit, Integer, default: PAGE_SIZE, max: MAX_QUEUED_ORDERS_REQUEST, message: "can't display more than top #{MAX_QUEUED_ORDERS_REQUEST} orders"
  Order.where(status: [:paid, :transmitting])
       .select(Order::PUBLIC_FIELDS)
       .order(bid_per_byte: :desc)
       .limit(params[:limit]).to_json(:only => Order::PUBLIC_FIELDS)
end

# GET /orders/sent
# params: 
#   before - return the previous PAGE_SIZE orders sent before the given time (time should be sent as in ISO 8601 format and defaults to now)
# returns:
#   array of JSON orders sorted in reverse chronological order
get '/orders/sent' do
  param :before, String, required: false, default: lambda { Time.now.utc.iso8601 }
  before = DateTime.iso8601(params[:before])
  Order.where(status: :sent).where("created_at < ?", before)
       .select(Order::PUBLIC_FIELDS)
       .order(upload_ended_at: :desc)
       .limit(PAGE_SIZE).to_json(:only => Order::PUBLIC_FIELDS)
end

# GET /orders/pending
# params: 
#   before - return the previous PAGE_SIZE orders sent before the given time (time should be sent as in ISO 8601 format and defaults to now)
# returns:
#   array of JSON orders sorted in reverse chronological order
get '/orders/pending' do
  param :before, String, required: false, default: lambda { Time.now.utc.iso8601 }
  before = DateTime.iso8601(params[:before])
  Order.where(status: :pending).where("created_at < ?", before)
       .select(Order::PUBLIC_FIELDS)
       .order(upload_ended_at: :desc)
       .limit(PAGE_SIZE).to_json(:only => Order::PUBLIC_FIELDS)
end

get '/orders/:uuid/message' do
  uuid_path_component = sanitize_uuid_param(params[:uuid])
  send_file File.join(MESSAGE_STORE_PATH, uuid_path_component), :disposition => 'attachment'
end

# POST /order
#  
# upload a message, along with a bid (in millisatoshis)
# return JSON object with status, uuid, and lightning payment invoice
post '/order' do
  param :bid, Integer, required: true
  param :file, Hash, required: true
  bid = Integer(params[:bid])

  # process the upload
  unless tmpfile = params[:file][:tempfile]
    halt 400, {:message => "Message upload problem", :errors => ["No tempfile received"]}.to_json
  end
  unless name = params[:file][:filename]
    halt 400, {:message => "Message upload problem", :errors => ["Filename missing"]}.to_json
  end

  order = Order.new(:bid => bid, :uuid => SecureRandom.uuid)
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
  if message_size < MIN_MESSAGE_SIZE
    FileUtils.rm(message_file)
    halt 400, {:message => "Message upload problem", :errors => ["Message too small. Minimum message size is #{MIN_MESSAGE_SIZE}"]}.to_json
  end

  order.message_size = message_size
  order.message_digest = sha256.to_s
  if order.bid_per_byte < MIN_PER_BYTE_BID
    halt 413, {:message => "Bid too low", :errors => ["Per byte bid cannot be below #{MIN_PER_BYTE_BID} millisatoshis per byte. The minimum bid for this message is #{order.message_size * MIN_PER_BYTE_BID} millisatoshis." ]}.to_json
  end

  invoice = new_invoice(order, bid)
  Order.transaction do
    order.save
    invoice.order = order
    invoice.save
  end
  
  {:auth_token => order.user_auth_token, :uuid => order.uuid, :lightning_invoice => JSON.parse(invoice.invoice)}.to_json
end

post '/order/:uuid/bump' do
  param :uuid, String, required: true
  param :bid, Integer, required: true
  param :auth_token, String, required: true, default: lambda { env['HTTP_X_AUTH_TOKEN'] },
        message: "auth_token must be provided either in the DELETE body or in an X-Auth-Token header"
  bid = Integer(params[:bid])
  
  unless order.bump
    halt 400, {:message => "Cannot bump order", :errors => ["Order already #{order.status}"]}.to_json
  end
  
  unless bid > order.bid
    halt 400, {:message => "Cannot bump order", :errors => ["New bid (#{bid}) must be larger than current bid (#{order.bid})"]}.to_json
  end
  
  invoice = new_invoice(order, bid - order.bid)
  order.bid = bid

  Order.transaction do
    order.save
    invoice.order = order
    invoice.save
  end
  
  {:auth_token => order.user_auth_token, :uuid => order.uuid, :lightning_invoice => JSON.parse(invoice.invoice)}.to_json
end

delete '/order/:uuid' do
  param :uuid, String, required: true
  param :auth_token, String, required: true, default: lambda { env['HTTP_X_AUTH_TOKEN'] },
        message: "auth_token must be provided either in the DELETE body or in an X-Auth-Token header"

  unless order.cancel!
    halt 400, {:message => "Cannot cancel order", :errors => ["Order already #{order.status}"]}.to_json
  end

  {:message => "order cancelled"}.to_json
end

# invoice paid callback from charged
post '/callback/:lid/:charged_auth_token' do
  param :lid, String, required: true
  param :charged_auth_token, String, required: true

  unless invoice.order.status == 'pending'
    halt 400, {:message => "Payment problem", :errors => ["Order already #{invoice.order.status}"]}.to_json
  end
  
  Order.transaction do
    invoice.update(:paid_at => Time.now)
    invoice.order.pay! if invoice.order.invoices_all_paid?    
  end
  
  {:message => "invoice #{invoice.lid} paid"}.to_json
end

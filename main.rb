require 'sinatra'
require "faraday"
require 'data_mapper'
require 'dm-noisy-failures'
require 'json'
require 'securerandom'

CHARGE_API_TOKEN = ENV['CHARGE_API_TOKEN'] || 'mySecretToken'
CHARGE_ROOT = ENV['CHARGE_ROOT'] || "http://api-token:#{CHARGE_API_TOKEN}@localhost:9112"
MIN_PER_BYTE_BID = 1 # minimum price per byte in msatoshis
KILO_BYTE = 2 ** 10
MEGA_BYTE = 2 ** 20
MAX_MESSAGE_SIZE = 1 * MEGA_BYTE
LN_INVOICE_EXPIRY = 60 * 10 # ten minutes
LN_INVOICE_DESCRIPTION = "BSS Test" # "Blockstream Satellite Transmission"

CALLBACK_URI_ROOT = ENV['CALLBACK_URI_ROOT'] || "http://localhost:4567"

require './helpers/init'
require './models/init'

configure do
  set :raise_errors, false
  set :show_exceptions, :after_handler
  
  DataMapper::Logger.new($stdout, :debug)
#  DataMapper::Model.raise_on_save_failure = true
  DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project.db")
  DataMapper.finalize

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
  # TODO remvove internal IDs before serving
  Order.all.to_json
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

  # TODO write order to db
  # create makes the resource immediately
  Order.create(
    :bid => params[:bid],
    :message => params[:message],
    :message_digest => message_digest,
    :status => :pending,
    :order_id => order_id,
    :lightning_invoice_id => lightning_invoice[:id],
    :lightning_invoice => lightning_invoice.to_json,
    :created_at => Time.now
  )
  
  # return lightning invoice
  lightning_invoice.to_json
end

delete 'cancel' do
  # TODO
end

post 'callback/:order_id/:token' do
  # TODO
  # authenticate the request
  # inspect updated invoice
  # if all is good, mark the order as paid = true
end

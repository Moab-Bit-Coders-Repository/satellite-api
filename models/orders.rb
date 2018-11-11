require_relative '../constants'
require_relative './invoices'
require_relative '../helpers/digest_helpers'

class Order
  include DataMapper::Resource
  PUBLIC_FIELDS = [:bid, :bid_per_byte, :message_size, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at]

  # FIXME add state machine validations, possibly with dm-is-state_machine
  VALID_STATUSES = [:pending, :paid, :transmitting, :sent, :cancelled]
  
  property :id,                     Serial
  property :bid,                    Integer # millisatoshis
  property :message_size,           Integer
  property :bid_per_byte,           Float, :scale => 2, :index => true # millisatoshis per byte
  property :message_digest,         String, :length => 64
  property :status,                 Enum[:pending, :paid, :transmitting, :sent, :cancelled]
  property :uuid,                   String, :index => true
  property :created_at,             DateTime, :required => true
  property :cancelled_at,           DateTime, :required => false
  property :upload_started_at,      DateTime, :required => false
  property :upload_ended_at,        DateTime, :required => false

  has n, :invoices
  
  def message_path
    File.join(MESSAGE_STORE_PATH, self.uuid)
  end
  
  # have all invoices been paid?
  def all_paid?
    self.invoices(:fields => [:paid_at]).map {|i| not i.paid_at.nil?}.reduce(:&)
  end
  
  USER_AUTH_KEY = hash_hmac('sha256', 'user-token', CHARGE_API_TOKEN)
  def user_auth_token
    hash_hmac('sha256', USER_AUTH_KEY, self.uuid)
  end
end

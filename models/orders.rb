require_relative '../constants'

class Order
  include DataMapper::Resource
  PUBLIC_FIELDS = [:bid, :bid_per_byte, :message_size, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at]
  
  def message_path
    File.join(MESSAGE_STORE_PATH, self.uuid)
  end
  
  property :id,                     Serial
  property :bid,                    Integer # millisatoshis
  property :message_size,           Integer
  property :bid_per_byte,           Float, :key => true # millisatoshis per byte
  property :message_digest,         String, :length => 64
  property :status,                 Enum[:pending, :paid, :transmitting, :sent, :cancelled]
  property :uuid,                   String, :key => true
  property :lightning_invoiceid,    String, :key => true
  property :lightning_invoice,      String, :length => 1024
  property :created_at,             DateTime, :required => true
  property :cancelled_at,           DateTime, :required => false
  property :upload_started_at,      DateTime, :required => false
  property :upload_ended_at,        DateTime, :required => false
end

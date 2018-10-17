# TODO add validations

class Order
  include DataMapper::Resource

  property :id,                     Serial
  property :bid,                    Integer, :key => true # msatoshis_per_byte
  property :message,                Text # XXX probably should be blob
  property :message_digest,         String
  property :status,                 Enum[:pending, :paid, :transmitting, :sent, :cancelled]
  property :order_id,               String, :key => true
  property :lightning_invoice_id,   String, :key => true
  property :lightning_invoice,      String
  property :created_at,             DateTime, :key => true
  property :cancelled_at,            DateTime, :key => true
  property :upload_started_at,      DateTime, :key => true
  property :upload_ended_at,        DateTime, :key => true
end

class Order
  include DataMapper::Resource
  PUBLIC_FIELDS = [:bid, :message, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at]

  property :id,                     Serial
  property :bid,                    Integer, :key => true # msatoshis_per_byte
  property :message,                Text # XXX probably should be blob
  property :message_digest,         String, :length => 64
  property :status,                 Enum[:pending, :paid, :transmitting, :sent, :cancelled]
  property :orderid,                String, :key => true
  property :lightning_invoiceid,    String, :key => true
  property :lightning_invoice,      String, :length => 1024
  property :created_at,             DateTime, :required => true
  property :cancelled_at,           DateTime, :required => false
  property :upload_started_at,      DateTime, :required => false
  property :upload_ended_at,        DateTime, :required => false
end

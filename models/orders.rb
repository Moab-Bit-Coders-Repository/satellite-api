class Order
  include DataMapper::Resource

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

require_relative '../constants'
require_relative './orders'

class Invoice
  include DataMapper::Resource
  
  property :id,         Serial
  property :lid,        String,  :required => true, :key => true  # lightning invoice id
  property :invoice,    String,  :required => true, :length => MAX_LIGHTNING_INVOICE_SIZE # lightning invoice JSON
  property :paid,       Boolean, :default => false
  property :created_at, DateTime, :required => true

  belongs_to :order,   :key => true
  
end

require_relative '../constants'
require_relative './orders'
require_relative '../helpers/digest_helpers'

class Invoice
  include DataMapper::Resource
  
  property :id,         Serial
  property :lid,        String,  :required => true, :key => true  # lightning invoice id
  property :invoice,    String,  :required => true, :length => MAX_LIGHTNING_INVOICE_SIZE # lightning invoice JSON
  property :paid,       Boolean, :default => false
  property :created_at, DateTime, :required => true

  belongs_to :order,   :key => true
  
  LIGHTNING_WEBHOOK_KEY = hash_hmac('sha256', 'charged-token', CHARGE_API_TOKEN)
  def charged_auth_token
    hash_hmac('sha256', LIGHTNING_WEBHOOK_KEY, self.lid)
  end
  
  def callback_url
    "#{CALLBACK_URI_ROOT}/callback/#{self.lid}/#{self.charged_auth_token}"
  end
  
end

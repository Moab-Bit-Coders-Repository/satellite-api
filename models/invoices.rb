require "sinatra/activerecord"
require_relative '../constants'
require_relative './orders'
require_relative '../helpers/digest_helpers'

class Invoice < ActiveRecord::Base
  validates :lid, presence: true
  validates :invoice, presence: true

  belongs_to :order
  
  LIGHTNING_WEBHOOK_KEY = hash_hmac('sha256', 'charged-token', CHARGE_API_TOKEN)
  def charged_auth_token
    hash_hmac('sha256', LIGHTNING_WEBHOOK_KEY, self.lid)
  end
  
  def callback_url
    "#{CALLBACK_URI_ROOT}/callback/#{self.lid}/#{self.charged_auth_token}"
  end
  
end

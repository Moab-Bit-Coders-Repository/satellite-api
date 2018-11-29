require_relative '../constants'
require_relative './invoices'
require_relative '../helpers/digest_helpers'

class Order < ActiveRecord::Base
  PUBLIC_FIELDS = [:bid, :bid_per_byte, :message_size, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at]

  # FIXME add state machine validations, possibly with dm-is-state_machine
  VALID_STATUSES = [:pending, :paid, :transmitting, :sent, :cancelled]
  
  enum status: [:pending, :paid, :transmitting, :sent, :cancelled]
  validates :bid, presence: true
  validates :message_size, presence: true
  validates :bid_per_byte, presence: true
  validates :message_digest, presence: true
  validates :status, presence: true
  validates :uuid, presence: true
  validates :created_at, presence: true

  has_many :invoices
  
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

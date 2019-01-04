require 'aasm'
require 'redis'
require 'json'
require_relative '../constants'
require_relative './invoices'
require_relative '../helpers/digest_helpers'

class Order < ActiveRecord::Base
  include AASM
  
  PUBLIC_FIELDS = [:uuid, :unpaid_bid, :bid, :bid_per_byte, :message_size, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at, :tx_seq_num]

  @@redis = Redis.new(url: REDIS_URI)
  
  enum status: [:pending, :paid, :transmitting, :sent, :cancelled]
  
  before_validation :adjust_bids
  
  validates :bid, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unpaid_bid, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :message_size, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: MIN_MESSAGE_SIZE }
  validates :message_digest, presence: true
  validates :bid_per_byte, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :uuid, presence: true

  has_many :invoices, after_add: :adjust_bids_and_save, after_remove: :adjust_bids_and_save
  
  aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
    state :pending, initial: true
    state :paid
    state :transmitting, before_enter: Proc.new { self.upload_started_at = Time.now }
    state :sent, before_enter: Proc.new { self.upload_ended_at = Time.now }
    state :cancelled, before_enter: Proc.new { self.cancelled_at = Time.now }
    
    event :pay do
      transitions :from => :pending, :to => :paid
      transitions :from => :paid, :to => :paid
    end

    event :transmit, :after => :notify_transmissions_channel do
      transitions :from => :paid, :to => :transmitting
    end

    event :end_transmission, :after => :notify_transmissions_channel do
      transitions :from => :transmitting, :to => :sent
    end

    event :cancel do
      transitions :from => [:pending, :paid], :to => :cancelled
    end
    
    event :bump do
      transitions :from => [:pending, :paid], :to => :pending
    end
  end
  
  def adjust_bids_and_save(invoice)
    self.adjust_bids
    self.save
  end
  
  def adjust_bids
    self.bid = paid_invoices_total
    self.bid_per_byte = (self.bid.to_f / self.message_size.to_f).round(2)
    self.unpaid_bid = unpaid_invoices_total
  end
  
  def paid_invoices_total
    self.invoices.where(status: :paid).pluck(:amount).reduce(:+) || 0
  end

  def unpaid_invoices_total
    self.invoices.where(status: :pending).pluck(:amount).reduce(:+) || 0
  end
  
  def notify_transmissions_channel
    @@redis.publish 'transmissions', self.to_json(:only => Order::PUBLIC_FIELDS)
  end
  
  def message_path
    File.join(MESSAGE_STORE_PATH, self.uuid)
  end
  
  # have all invoices been paid?
  def invoices_all_paid?
    self.invoices.pluck(:paid_at).map {|i| not i.nil?}.reduce(:&)
  end
  
  USER_AUTH_KEY = hash_hmac('sha256', 'user-token', CHARGE_API_TOKEN)
  def user_auth_token
    hash_hmac('sha256', USER_AUTH_KEY, self.uuid)
  end

  def as_sanitized_json
    self.to_json(:only => Order::PUBLIC_FIELDS)
  end

end

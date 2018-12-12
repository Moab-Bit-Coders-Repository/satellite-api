require 'aasm'
require_relative '../constants'
require_relative './invoices'
require_relative '../helpers/digest_helpers'

class Order < ActiveRecord::Base
  include AASM
  before_validation :set_bid_per_byte
  
  PUBLIC_FIELDS = [:uuid, :bid, :bid_per_byte, :message_size, :message_digest, :status, :created_at, :upload_started_at, :upload_ended_at]

  # FIXME add state machine validations, possibly with dm-is-state_machine
  VALID_STATUSES = [:pending, :paid, :transmitting, :sent, :cancelled]
  
  enum status: [:pending, :paid, :transmitting, :sent, :cancelled]
  validates :bid, presence: true, numericality: { only_integer: true }
  validates :message_size, presence: true, numericality: { only_integer: true }
  validates :message_digest, presence: true
  validates :bid_per_byte, presence: true, numericality: { greater_than_or_equal_to: MIN_PER_BYTE_BID }
  validates :status, presence: true
  validates :uuid, presence: true

  has_many :invoices
  
  aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
    state :pending, initial: true
    state :paid
    state :transmitting, before_enter: Proc.new { self.upload_started_at = Time.now }
    state :sent, before_enter: Proc.new { self.upload_ended_at = Time.now }
    state :cancelled, before_enter: Proc.new { self.cancelled_at = Time.now }
    
    event :pay do
      transitions :from => :pending, :to => :paid
    end

    event :start_transmission do
      transitions :from => :paid, :to => :transmitting
    end

    event :end_transmission do
      transitions :from => :transmitting, :to => :sent
    end

    event :cancel do
      transitions :from => [:pending, :paid], :to => :cancelled
    end
    
    event :bump do
      transitions :from => [:pending, :paid], :to => :pending
    end
  end
  
  def message_path
    File.join(MESSAGE_STORE_PATH, self.uuid)
  end
  
  # have all invoices been paid?
  def invoices_all_paid?
    self.invoices(:fields => [:paid_at]).map {|i| not i.paid_at.nil?}.reduce(:&)
  end
  
  USER_AUTH_KEY = hash_hmac('sha256', 'user-token', CHARGE_API_TOKEN)
  def user_auth_token
    hash_hmac('sha256', USER_AUTH_KEY, self.uuid)
  end

  def bid_per_byte
    super || self.computed_bid_per_byte
  end

  def computed_bid_per_byte
    (self.bid.nil? or self.message_size.nil?) ? nil : (self.bid.to_f / self.message_size.to_f).round(2)
  end

  def set_bid_per_byte
    self.bid_per_byte = self.computed_bid_per_byte
  end

end

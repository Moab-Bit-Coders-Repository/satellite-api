require 'aasm'
require_relative '../constants'
require_relative './invoices'
require_relative '../helpers/digest_helpers'

class Order < ActiveRecord::Base
  include AASM
  
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

  has_many :invoices
  
   
  aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
    state :pending, initial: true
    state :paid
    state :transmitting, before_enter: Proc.new { self.upload_started_at = Time.now }
    state :sent, before_enter: Proc.new { self.upload_ended_at = Time.now }
    state :cancelled, before_enter: Proc.new { self.cancelled_at = Time.now }
    
    after_all_transitions :log_status_change
    
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
  
  def log_status_change
    puts "changing from #{aasm.from_state} to #{aasm.to_state} (event: #{aasm.current_event})"
  end
  
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

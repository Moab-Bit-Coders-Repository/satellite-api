require 'active_record'
require_relative '../constants'
require_relative '../models/init'

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = nil
  while sendable_order.nil? do
    Order.transaction do
      sendable_order = Order.where(status: :paid).order(bid_per_byte: :desc).first
      sendable_order.update(:status => :transmitting, :upload_started_at => Time.now) if sendable_order
    end
    sleep 1
  end  
  
  if TRANSMIT_RATE_LIMIT
    sleep Float(sendable_order.message_size) / TRANSMIT_RATE_LIMIT
  end
  sendable_order.send!

  # TODO transmit the message to the satellite uplink stations
end

require 'active_record'
require_relative '../constants'
require_relative '../models/init'

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = nil
  while sendable_order.nil? do
    sleep 1
    Order.transaction do
      sendable_order = Order.where(status: :paid).order(bid_per_byte: :desc).first
      sendable_order.transmit! if sendable_order
    end
  end  
  
  sendable_order.transmit!
  if TRANSMIT_RATE_LIMIT
    sleep Float(sendable_order.message_size) / TRANSMIT_RATE_LIMIT
  end
  sendable_order.end_transmission!
end

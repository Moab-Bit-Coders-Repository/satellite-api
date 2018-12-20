require 'active_record'

require 'logger'
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

require_relative '../constants'
require_relative '../models/init'

# complete any old transmissions that could be stuck (e.g. by early termination of the transmitter daemon)
Order.transmitting.each do |order|
  logger.info "completing stuck transmission #{order.uuid}"
  order.end_transmission!
end

# NB: no mutex is needed around max_tx_seq_num because it is assumed that there is only one transmitter
max_tx_seq_num = Order.maximum(:tx_seq_num) || 0

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = nil
  while sendable_order.nil? do
    sleep 1
    
    Order.transaction do
      sendable_order = Order.where(status: :paid).order(bid_per_byte: :desc).first
      if sendable_order
        logger.info "transmission start #{sendable_order.uuid}"
        max_tx_seq_num += 1
        sendable_order.update(tx_seq_num: max_tx_seq_num)
        sendable_order.transmit!
      end
    end
  end  
  
  if TRANSMIT_RATE_LIMIT
    transmit_time = Float(sendable_order.message_size) / TRANSMIT_RATE_LIMIT
    logger.info "sleeping for #{transmit_time} while #{sendable_order.uuid} transmits"
    sleep transmit_time
  end
  
  logger.info "transmission end #{sendable_order.uuid}"
  sendable_order.end_transmission!
end

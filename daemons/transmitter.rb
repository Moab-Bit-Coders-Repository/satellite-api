require 'data_mapper'
require 'json'

require_relative '../dm_config'
require_relative '../fifo_config'

SLEEP_TIME = 1

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = Order.first(:status => :paid, :order => [:bid.desc])
  if sendable_order
    # TODO handle IOErrors exceptions
    sendable_order.status = :transmitting
    sendable_order.upload_started_at = Time.now
    sendable_order.save
    
    # TODO fix status updates and uploaded_at timestamps
    File.open(sendable_order.message_path, "rb") do |message_file|
      File.open(FIFO_PIPE_PATH, "wb") do |pipe|
        IO.copy_stream(message_file, pipe, sendable_order.message_size)
      end
    end
    
    sendable_order.status = :sent
    sendable_order.upload_ended_at = Time.now
    sendable_order.save
  end
  
  # TODO consider sleeping for as long as it will take to transmit the message just sent
  sleep SLEEP_TIME
end

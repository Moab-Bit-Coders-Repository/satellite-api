require 'data_mapper'
require 'json'

require_relative '../db_config'
require_relative '../fifo_config'

SLEEP_TIME = 1

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = nil
  while sendable_order.nil? do
    Order.transaction do
      sendable_order = Order.first(:status => :paid, :order => [:bid.desc])
      sendable_order.update(:status => :transmitting, :upload_started_at => Time.now) if sendable_order
    end
    sleep SLEEP_TIME # TODO consider variable sleep to simulate transmission rate
  end  
  
  # TODO handle IOErrors exceptions
  File.open(sendable_order.message_path, "rb") do |message_file|
    File.open(FIFO_PIPE_PATH, "wb") do |pipe|
      IO.copy_stream(message_file, pipe, sendable_order.message_size)
    end
  end
  
  sendable_order.update(:status => :sent, :upload_ended_at => Time.now)
end

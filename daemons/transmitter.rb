require 'data_mapper'
require 'json'

require '../models/init'

FIFO_PIPE_PATH = "/tmp/src" # named pipe with GNU radio sitting on the other end
SLEEP_TIME = 1

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project.db")
DataMapper.finalize

# loop forever dequing the highest-priced paid order and piping it to the GNU radio FIFO
loop do
  sendable_order = Order.first(:status => :paid, :order => [:bid.desc])
  if sendable_order
    # TODO handle IOErrors
    sendable_order.status = :transmitting
    sendable_order.save
    IO.write(FIFO_PIPE_PATH, sendable_order.message)
    sendable_order.status = :sent
    sendable_order.save
  end
  
  # TODO consider sleeping for as long as it will take to transmit the message just sent
  sleep SLEEP_TIME
end

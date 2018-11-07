require_relative '../constants'
require_relative '../helpers/init'
require_relative '../fifo_config'

RECEIVED_MESSAGE_STORE_PATH = File.join(MESSAGE_STORE_PATH, 'received')
Dir.mkdir(RECEIVED_MESSAGE_STORE_PATH) unless File.exists?(RECEIVED_MESSAGE_STORE_PATH)

loop do
  pipe = File.open(FIFO_PIPE_PATH, "rb")

  # FIXME buffer the IO, don't just slurp the whole file into memory
  contents = pipe.read

  message_digest = sha256_digest(contents)
  fn = "#{RECEIVED_MESSAGE_STORE_PATH}/#{message_digest}"
  f = File.new(fn, "w")

  f.write(contents)
  puts "wrote #{contents.length} bytes to #{fn}"

  f.close
end

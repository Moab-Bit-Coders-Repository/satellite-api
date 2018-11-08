require 'tempfile'
require 'fileutils'
require 'openssl'

require_relative '../constants'
require_relative '../helpers/init'
require_relative '../fifo_config'

Dir.mkdir(SENT_MESSAGE_STORE_PATH) unless File.exists?(SENT_MESSAGE_STORE_PATH)

loop do
  pipe = File.open(FIFO_PIPE_PATH, "rb")
  tmpfile = File.open(Tempfile.new, 'wb')

  sha256 = OpenSSL::Digest::SHA256.new
  while block = pipe.read(65536)
    sha256 << block
    tmpfile.write(block)
    STDERR.puts "read block"
  end
  pipe.close()
  tmpfile.close()

  FileUtils.mv(tmpfile.path, "#{SENT_MESSAGE_STORE_PATH}/#{sha256.to_s}")
  STDERR.puts "moved file"
  
end

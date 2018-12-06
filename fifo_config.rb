require_relative 'constants'
File.mkfifo(FIFO_PIPE_PATH) unless File.exists?(FIFO_PIPE_PATH)

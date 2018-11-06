FIFO_PIPE_PATH = "/tmp/src" # named pipe with GNU radio sitting on the other end
File.mkfifo(FIFO_PIPE_PATH) unless File.exists?(FIFO_PIPE_PATH)

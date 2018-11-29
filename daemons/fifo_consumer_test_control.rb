require 'daemons'

options = {
  ontop: false,
  backtrace: true,
  log_output: true,
  multiple: false
}

Daemons.run('test/fifo2files.rb', options)

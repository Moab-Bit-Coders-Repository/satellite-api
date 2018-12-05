require 'daemons'

options = {
  ontop: false,
  backtrace: true,
  log_output: true,
  multiple: false
}

Daemons.run('daemons/transmitter.rb', options)

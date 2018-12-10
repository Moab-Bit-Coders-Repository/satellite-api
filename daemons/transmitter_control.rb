require 'active_record'
require_relative '../constants'
require_relative '../models/init'
require 'daemons'

options = {
  ontop: false,
  backtrace: true,
  log_output: true,
  multiple: false
}

Daemons.run('daemons/transmitter.rb', options)

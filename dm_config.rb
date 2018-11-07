require 'data_mapper'
require_relative 'constants'
require_relative './models/init'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{DB_PATH}")
DataMapper.finalize

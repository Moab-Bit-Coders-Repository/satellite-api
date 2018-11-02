require 'data_mapper'
require_relative './models/init'

DB_PATH = ENV['DB_PATH'] || '/data/ionosphere/ionosphere.db'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite://#{DB_PATH}")
DataMapper.finalize

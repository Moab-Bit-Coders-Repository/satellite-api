require 'sinatra'
require 'sinatra/activerecord'
require_relative 'constants'
require_relative './models/init'

set :database, {adapter: "sqlite3", database: DB_PATH, pool: 2}

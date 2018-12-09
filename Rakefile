require 'sinatra/activerecord'
require "sinatra/activerecord/rake"
require_relative 'constants'

Rake::Task['db:drop'].enhance do
  FileUtils.remove_entry_secure(MESSAGE_STORE_PATH)
end

Rake::Task['db:create'].enhance do
  FileUtils.mkdir_p(SENT_MESSAGE_STORE_PATH)
end

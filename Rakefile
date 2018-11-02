require 'dm-migrations'
require_relative 'dm_config'

desc "auto migrates the database"
task :migrate do
  DataMapper.auto_migrate!
end

desc "auto upgrades the database"
task :upgrade do
  DataMapper.auto_upgrade! 
end

#Created to be used with ruby >= 1.9
require 'benchmark'
require 'date'
require_relative 'models/colors'

def usage
  puts 'Usage:'
  puts 'ID=12345678901234567890 ruby database_load.rb'
  puts
  abort
end

time = Benchmark.realtime do
  if !ENV['ID']
    usage
  end

  directory = ''
  directory = "DIRECTORY=#{ENV['DIRECTORY']}" if ENV['DIRECTORY']

  import = "ID=#{ENV['ID']} ruby importer.rb"
  generate_sql = "ruby sql_generator.rb"
  restore_mysql = "ruby mysql_import.rb"

  system(import)
  system(generate_sql)
  system(restore_mysql)
end

puts
puts 'Done.'
puts "Time elapsed #{time} seconds"
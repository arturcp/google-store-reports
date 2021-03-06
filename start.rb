require 'benchmark'
require_relative 'models/colors'

def usage
  puts 'Usage:'
  puts
  puts 'ID=12345678901234567890 YEAR=2015 MONTH=7 ruby start.rb'.green
  puts
  puts 'All fields are mandatory'
  puts
end

def validate_required_fields
  if !ENV['ID'] || !ENV['YEAR'] || !ENV['MONTH']
    usage
    abort
  end
end

def start
  import = "ID=#{ENV['ID']} YEAR=#{ENV['YEAR']} MONTH=#{ENV['MONTH']} ruby importer.rb"
  generate_sql = "ruby sql_generator.rb"
  restore_mysql = "ruby mysql_import.rb"

  system(import)
  system(generate_sql)
  system(restore_mysql)
end

time = Benchmark.realtime do
  validate_required_fields
  start
end

puts ''
puts 'Done.'
puts "Time elapsed #{time} seconds"
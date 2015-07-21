require 'fileutils'
require 'benchmark'
require 'json'
require_relative 'models/colors'

def start
  path = './config.json'
  if File.exists?(path)
    file = File.open(path, "rb:UTF-8")
    config = JSON.parse(file.read)

    Dir.glob("./sql/*.sql").each do |file|
      puts "importing #{file.light_blue}"
      cmd = "mysql -u#{config['username']} -p#{config['password']} #{config['database']} < #{file}"
      system(cmd)
      File.delete(file)
    end
  else
    puts
    puts 'You need to configure your database settings. To do that, run: '
    puts
    puts "cp config.json.sample config.json".green
    puts
    puts 'Make sure you change the default data with your own database connection information'
    abort
  end
end

time = Benchmark.realtime do
  start
end

puts ''
puts 'Done.'
puts "Time elapsed #{time} seconds"
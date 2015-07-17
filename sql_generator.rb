require 'benchmark'
require 'fileutils'

require_relative 'colors'

DEFAULT_DIRECTORY = './reports'
REPORTS = ['installs', 'ratings', 'crashes']
INSERT = 'INSERT INTO %{table_name} (%{columns}) VALUES (%{values});'
OUTPUT_FILE_NAME = Time.now.strftime('%Y%m%d%H%M%S%L')

def welcome_message
  puts '+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+'
  puts "|#{"G".light_blue}|#{"o".red}|#{"o".yellow}|#{"g".light_blue}|#{"l".green}|#{"e".red}| |C|S|V| |I|m|p|o|r|t|e|r|"
  puts '+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+'
  puts ''
end

def sql_message
  puts '** Important **'.yellow
  puts ''
  puts "The script will generate a .sql file with the insert commands to generate the database. The file will be available at #{"./sql".light_blue}"
  puts ''
end

def directory_message
  unless ENV['DIRECTORY']
    puts "* No directory was provided. The reports will be stored in #{DEFAULT_DIRECTORY.light_blue}"
  end
  puts ''
end

def format_columns(columns)
  columns.map do |column|
    "'#{column.downcase.strip.gsub(' ', '_').gsub(/[^\w-]/, '').gsub("\n", '')}'" unless column.nil?
  end.join(', ')
end

def format_values(values)
  values.map do |value|
    "'#{value}'".gsub("\n", '')
  end.join(', ')
end

def write_to_log(error)
  directory = './logs'
  filename = "#{directory}/#{OUTPUT_FILE_NAME}.log"

  unless File.directory?(directory)
    FileUtils::mkdir_p(directory)
  end

  file_mode = File.exists?(filename) ? 'a+' : 'w+'
  File.open(filename, file_mode) { |file| file.write("#{error}\n") }
end

def write_to_file(inserts)
  directory = './sql'
  filename = "#{directory}/#{OUTPUT_FILE_NAME}.sql"

  unless File.directory?(directory)
    puts "#{"[Warning]".gray}: #{directory} did not exist and was created"
    FileUtils::mkdir_p(directory)
  end

  file_mode = File.exists?(filename) ? 'a' : 'w'
  open(filename, "#{file_mode}:UTF-8") { |file| file.write(inserts.join("\n")) }
end

def import_csv(file)
    inserts = []
    imported_file_name = file.split('/').last
    inserts << "-- #{imported_file_name}"

    lines = File.open(file, "rb:UTF-16LE") { |f| f.readlines }

    columns = lines.shift.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '').split(',')

    lines.each do |line|
      line.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '')

      item = {}
      values = line.split(',')

      if values.length > 1
        inserts << INSERT % { table_name: 'table_name', columns: format_columns(columns), values: format_values(values) }
      end
    end
    inserts << " \n "

    write_to_file(inserts)
    dots = '.' * (120 - imported_file_name.length).abs
    puts "* #{imported_file_name.light_blue} #{dots} #{"done".green}"
  rescue => e
   puts "* #{imported_file_name.light_blue} #{dots} #{"error".red}"
   write_to_log("#{e} \n #{e.backtrace}")
end

def start
  welcome_message
  directory_message
  sql_message

  puts 'Starting SQL generation...'
  puts '=========================='
  puts ''

  directory = ENV['DIRECTORY'] || DEFAULT_DIRECTORY
  REPORTS.each do |report|
    Dir.glob("#{directory}/#{report}/*.csv").each do |csv|
      import_csv(csv)
    end
  end
end

time = Benchmark.realtime do
  start
end

puts ''
puts 'Done.'
puts "Time elapsed #{time} seconds"
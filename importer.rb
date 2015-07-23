#Created to be used with ruby >= 1.9

require 'fileutils'
require 'benchmark'
require_relative 'models/colors'

DEFAULT_DIRECTORY = './reports'

# You can also download reports from 'ratings' and 'crashes'
REPORTS = ['installs']

# Leave this variable blank to download all csvs: app_version, carrier, country, device, language, os_version, overview and tablets
FILTER_BY_REPORT = 'overview'

def welcome_message
  puts "+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+"
  puts "|#{"G".light_blue}|#{"o".red}|#{"o".yellow}|#{"g".light_blue}|#{"l".green}|#{"e".red}| |P|l|a|y| |I|m|p|o|r|t|e|r|"
  puts "+-+-+-+-+-+-+ +-+-+-+-+ +-+-+-+-+-+-+-+-+"

  puts ''
  puts 'Make sure you have gsutils installed and configured before running the importer. You can find more information in the following links: '
  puts 'https://cloud.google.com/storage/docs/gsutil'
  puts 'https://cloud.google.com/storage/docs/gsutil_install'
  puts ''
end

def url_prefix
  @url_prefix ||= begin
    url = "gs://pubsite_prod_rev_%{id}/stats/"
    url % { id: ENV['ID'] || '00000000000000000000' }
  end
end

def directory_message
  unless ENV['DIRECTORY']
    puts '** IMPORTANT **'.yellow
    puts "No directory was provided. The reports will be stored in #{DEFAULT_DIRECTORY.light_blue}"
    puts ''
  end
end

def required_fields_message
  unless ENV['ID']
    puts 'The ID is required to run the script correctly. Check the usage:'
    puts

    puts "ID=12345678901234567890 ruby importer.rb".green
    puts
    puts 'In the example above, replace the number 12345678901234567890 with your own id.'
    abort
  end
end

def assert_directory_exists(directory)
  unless File.directory?(directory)
    puts "#{"[Warning]".gray}: #{directory} did not exist and was created"
    FileUtils::mkdir_p(directory)
  end
end

def gsutil_command(path, directory)
  year = ENV['YEAR']
  month = ENV['MONTH']
  wildcard = ''

  if year && month
    wildcard = "/*#{year}#{month.rjust(2, '0')}*#{FILTER_BY_REPORT}.csv"
  else
    wildcard = "/*#{FILTER_BY_REPORT}.csv"
  end

  "gsutil -m cp -r #{path}#{wildcard} #{directory}"
end

def import_files(base_directory)
  puts '*********** Starting Import ***********'
  REPORTS.each_with_index do |report, index|
    path = "#{url_prefix}#{report}"
    report_directory = "#{base_directory}/#{report}"

    puts "#{index + 1}. Importing #{report} from #{path} and storing in #{report_directory.light_blue}"
    assert_directory_exists(report_directory)

    cmd = gsutil_command(path, report_directory)
    system(cmd)
  end
  puts '***************************************'
end

def start
  welcome_message
  directory_message
  required_fields_message

  directory = ENV['DIRECTORY'] || DEFAULT_DIRECTORY

  import_files(directory)
end

time = Benchmark.realtime do
  start
end

puts ''
puts 'Done.'
puts "Time elapsed #{time} seconds"

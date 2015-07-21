require 'benchmark'
require 'fileutils'

require_relative 'colors'
require_relative 'product'
require_relative 'sale'

DEFAULT_DIRECTORY = './reports'
REPORTS = ['installs']
INSERT_IGNORE = 'INSERT IGNORE INTO %{table_name} (%{columns}) VALUES (%{values});'
INSERT = 'INSERT INTO %{table_name} (%{columns}) VALUES (%{values});'
UPDATE = 'UPDATE %{table_name} SET icon_path = %{icon_path}, active = %{active}, version = %{version}, last_update = %{last_update} WHERE package_name = %{package_name};'

OUTPUT_FILE_NAME = Time.now.strftime('%Y%m%d%H%M%S%L')

# Leave this variable blank to download all csvs: app_version, carrier, country, device, language, os_version, overview and tablets
FILTER_BY_REPORT = 'overview'

Product.crawled_products = []

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

def write_extra_data_to_file(data)
  updates = ["-- UPDATE PRODUCTS REPORT"]

  data.each do |product|
    updates << UPDATE % {
      table_name: Product.table,
      icon_path: "'#{product[:icon_path]}'",
      active: "#{product[:active]}",
      version: "'#{product[:version]}'",
      last_update: "'#{product[:last_update]}'",
      package_name: "'#{product[:package_name]}'"
    }
  end

  updates << " \n "
  write_to_file(updates)
end

def import_products(imported_file_name, columns, lines)
  inserts = ["-- PRODUCTS REPORT: #{imported_file_name}"]
  data = []

  lines.each do |line|
    line.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '')

    item = {}
    values = line.split(',')

    product = Product.new(columns, values)

    if values.length > 1
      inserts << INSERT_IGNORE % { table_name: Product.table, columns: product.columns, values: product.values }

      unless Product.crawled_products.include?(product.package_name)
        data << product.crawl_data
        Product.crawled_products << product.package_name
      end
    end
  end

  inserts << " \n "
  write_to_file(inserts)
  write_extra_data_to_file(data)
end

def import_sales(imported_file_name, columns, lines)
  inserts = ["-- SALES REPORT #{imported_file_name}"]

  lines.each do |line|
    item = {}
    values = line.split(',')

    sale = Sale.new(columns, values)

    if values.length > 1
      inserts << INSERT % { table_name: Sale.table, columns: sale.columns, values: sale.values }
    end
  end

  inserts << " \n "
  write_to_file(inserts)
end

def update_field_sum(field)
  sql = "UPDATE #{Product.table} p " +
        "INNER JOIN (" +
        "  SELECT product_id, SUM(#{field}) as #{field}" +
        "  FROM #{Sale.table}" +
        "  GROUP BY product_id" +
        ") s ON s.product_id = p.id" +
        " SET p.#{field} = s.#{field};"
end

def calculate_related_fields
  inserts = ["-- RELATED VALUES"]

  inserts << update_field_sum('downloads')
  inserts << update_field_sum('revenue')
  inserts << update_field_sum('updates')
  inserts << " \n "
  write_to_file(inserts)
end

def import_csv(file)
    imported_file_name = file.split('/').last
    lines = File.open(file, "rb:UTF-16LE") { |f| f.readlines }
    columns = lines.shift.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '').split(',')

    import_products(imported_file_name, columns, lines)
    import_sales(imported_file_name, columns, lines)

    dots = '.' * (120 - imported_file_name.length).abs
    puts "* #{imported_file_name.light_blue} #{dots} #{"done".green}"
    #File.delete(file)
  #rescue => e
  # puts "* #{imported_file_name.light_blue} #{dots} #{"error".red}"
  # write_to_log("#{e} \n #{e.backtrace}")
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
    Dir.glob("#{directory}/#{report}/*#{FILTER_BY_REPORT}.csv").each do |csv|
      import_csv(csv)
    end
  end

  calculate_related_fields
end

time = Benchmark.realtime do
  start
end

puts ''
puts 'Done.'
puts "Time elapsed #{time} seconds"
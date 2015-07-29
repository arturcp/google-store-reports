require 'benchmark'
require 'fileutils'

require_relative 'models/colors'
require_relative 'models/product'
require_relative 'models/sale'
require_relative 'models/file_writer'

DEFAULT_DIRECTORY = './reports'
REPORTS = ['installs']

DELETE = 'DELETE s.* FROM %{sales_table_name} s INNER JOIN %{products_table_name} p on s.product_id = p.id where YEAR(collected_date) = %{year} and MONTH(collected_date) = %{month} and p.store = "google";'

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

def write_extra_data_to_file(products)
  queries = ["-- UPDATE PRODUCTS REPORT"]

  products.each do |product|
    if product.active
      queries << product.update_script
    else
      queries << product.deactivate_script
    end
  end

  queries << " \n "
  FileWriter.script(OUTPUT_FILE_NAME, queries)
end

def import_products(imported_file_name, columns, lines)
  queries = ["-- PRODUCTS REPORT: #{imported_file_name}"]
  products = []

  lines.each do |line|
    line.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '')
    values = line.split(',')

    product = Product.new(columns, values)

    if values.length > 1
      queries << product.insert_script

      unless Product.crawled_products.include?(product.package_name)
        products << product.crawl_data
        Product.crawled_products << product.package_name
      end
    end
  end

  queries << " \n "
  FileWriter.script(OUTPUT_FILE_NAME, queries)
  write_extra_data_to_file(products)
end

def import_sales(imported_file_name, columns, lines)
  queries = ["-- SALES REPORT #{imported_file_name}"]

  lines.each do |line|
    values = line.split(',')
    sale = Sale.new(columns, values)
    queries << sale.insert_script if values.length > 1
  end

  queries << " \n "
  FileWriter.script(OUTPUT_FILE_NAME, queries)
end

def update_field_sum(field)
  sql = "UPDATE #{Product.table} p " +
        "INNER JOIN (" +
        "  SELECT product_id, SUM(#{field}) as #{field}" +
        "  FROM #{Sale.table}" +
        "  GROUP BY product_id" +
        ") s ON s.product_id = p.id" +
        " SET p.#{field} = s.#{field} " +
        " WHERE p.store = 'Google'; "
end

def calculate_related_fields
  queries = ["-- RELATED VALUES"]

  queries << update_field_sum('downloads')
  queries << update_field_sum('revenue')
  queries << update_field_sum('updates')
  queries << " \n "
  FileWriter.script(OUTPUT_FILE_NAME, queries)
end

def import_csv(file)
    imported_file_name = file.split('/').last
    lines = File.open(file, "rb:UTF-16LE") { |f| f.readlines }
    columns = lines.shift.encode!('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '').split(',')

    import_products(imported_file_name, columns, lines)
    import_sales(imported_file_name, columns, lines)

    dots = '.' * (120 - imported_file_name.length).abs
    puts "* #{imported_file_name.light_blue} #{dots} #{"done".green}"
    File.delete(file)
  rescue => e
   puts "* #{imported_file_name.light_blue} #{dots} #{"error".red}"
   FileWriter.log(OUTPUT_FILE_NAME, "#{e} \n #{e.backtrace}")
end

def delete_old_sales_data(directory)
  queries = ['-- DELETE OLD SALES DATA']
  dates = []

  REPORTS.each do |report|
    Dir.glob("#{directory}/#{report}/*#{FILTER_BY_REPORT}.csv").each do |csv|
        parts = csv.split('_')
        dates << Date.strptime(parts[-2], '%Y%m')
    end
  end

  dates.uniq.each do |date|
    queries << DELETE % {
      sales_table_name: Sale.table,
      products_table_name: Product.table,
      year: date.year,
      month: date.month
    }
  end

  queries << "\n"
  FileWriter.script(OUTPUT_FILE_NAME, queries)
end

def start
  welcome_message
  directory_message
  sql_message

  puts 'Starting SQL generation...'
  puts '=========================='
  puts ''

  directory = ENV['DIRECTORY'] || DEFAULT_DIRECTORY
  delete_old_sales_data(directory)

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
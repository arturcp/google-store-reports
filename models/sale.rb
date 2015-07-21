require_relative 'product'

class Sale
  attr_accessor :product_id, :downloads, :updates, :revenue, :collected_date

  TABLE = '`dashboard`.`appfigures_sales`'
  COLUMNS = %w(product_id downloads updates revenue collected_date)

  def initialize(columns, values)
    hash = Hash[columns.zip(values)]
    self.product_id = hash['Package Name']
    self.downloads = hash['Daily User Installs']
    self.updates = hash['Daily Device Upgrades']
    date_key = hash.keys.first
    self.collected_date = hash[date_key]
  end

  def columns
    COLUMNS.map { |column| "#{column}" }.join(', ')
  end

  def values
    "#{product_query}, #{downloads}, #{updates}, 0, '#{collected_date}'"
  end

  def product_query
    "(select id from #{Product.table} where package_name = '#{self.product_id}' limit 1)"
  end

  def self.table
    TABLE
  end

  private

  def fields
    [product_id, downloads, updates, revenue, collected_date]
  end
end
require 'open-uri'
require_relative 'colors'
require_relative 'db_config'

class Product
  attr_accessor :product_id, :name, :icon_path, :sku,
    :package_name, :store, :release_date, :last_update,
    :last_version, :app_type, :downloads, :updates, :revenue,
    :active, :id_trademark, :apikey_flurry, :apikey_flurry2, :observation

  TABLE = '`%{database}`.`appfigures_products`'
  COLUMNS = %w(product_id name icon_path sku package_name store release_date last_update last_version app_type downloads updates revenue active id_trademark apikey_flurry apikey_flurry2 observation)
  INSERT = 'INSERT IGNORE INTO %{table_name} (%{columns}) VALUES (%{values});'
  UPDATE = 'UPDATE %{table_name} SET icon_path = %{icon_path}, active = %{active}, last_version = %{version}, last_update = %{last_update} WHERE package_name = %{package_name};'
  DEACTIVATE = 'UPDATE %{table_name} SET active = false WHERE package_name = %{package_name};'

  @@crawled_products = {}

  def initialize(columns, values)
    hash = Hash[columns.zip(values)]
    self.product_id = hash['Package Name']
    self.name = hash['Package Name']
    self.package_name = hash['Package Name']
    self.store = 'Google'

    self.sku = ''
    self.release_date = nil
    self.last_update = nil
    self.last_version = 0
    self.app_type = ''
    self.downloads = nil
    self.updates = nil
    self.revenue = nil
    self.id_trademark = ''
    self.apikey_flurry = ''
    self.apikey_flurry2 = ''
    self.observation = ''

    self.icon_path = ''
    self.active = active?
  end

  def columns
    COLUMNS.map { |column| "#{column}" }.join(', ')
  end

  def values
    fields.map do |value|
      if ['true', 'false'].include?(value.to_s)
        value
      elsif ['nil', ''].include?(value.to_s)
        'null'
      else
        "'#{value}'"
      end
    end.join(', ')
  end

  def active?
    true
  end

  def insert_script
    INSERT % { table_name: Product.table, columns: self.columns, values: self.values }
  end

  def update_script
    UPDATE % {
      table_name: Product.table,
      icon_path: "'#{icon_path}'",
      active: "#{active}",
      version: "'#{last_version}'",
      last_update: "'#{last_update}'",
      package_name: "'#{package_name}'"
    }
  end

  def deactivate_script
    DEACTIVATE % { table_name: Product.table, package_name: "'#{package_name}'" }
  end

  def crawl_data
    self.icon_path = ''
    self.active = false
    self.last_version = ''
    self.last_update = ''

    begin
      url = "https://play.google.com/store/apps/details?id=#{package_name}"
      message = "Fetching extra data from #{url}"

      open(url) do |f|
        body = f.readlines.join(' ')
        self.icon_path = image_url(body)
        self.active = self.icon_path.to_s != ''
        self.last_version = version(body)
        self.last_update = updated_at(body)
      end

      puts "#{"[success]".green} #{message}"
    rescue => e
      puts "#{"[fail]".red} #{message}"
      puts e
    end

    self
  end

  def self.crawled_products
    @@crawled_products
  end

  def self.crawled_products=(value)
    @@crawled_products = value
  end

  def self.table
    @table ||= begin
      TABLE % { database: DBConfig.database }
    end
  end

  private

  def fields
    [
      product_id, name, icon_path, sku, package_name, store, release_date, last_update,
      last_version, app_type, downloads, updates, revenue, active, id_trademark,
      apikey_flurry, apikey_flurry2, observation
    ]
  end

  def image_url(body)
    regex = /<img class=\"cover-image\" src=\"([\w\:\/\.\-\_\=]+)\" alt=\"Cover art\" aria-hidden=\"true\" itemprop=\"image\">/i
    body.scan(regex).flatten.first
  end

  def version(body)
    regex = /<div class=\"content\" itemprop=\"softwareVersion\">([\w\.\s\-]+)<\/div>/
    body.scan(regex).flatten.first.strip
  end

  def updated_at(body)
    regex = /<div class=\"content\" itemprop=\"datePublished\">([\w\.\s\-]+)<\/div>/
    date = body.scan(regex).flatten.first
    date = date.gsub(/\sde\s/, '')
               .gsub('janeiro', '/01/')
               .gsub('fevereiro', '/02/')
               .gsub('março', '/03/')
               .gsub('abril', '/04/')
               .gsub('maio', '/05/')
               .gsub('junho', '/06/')
               .gsub('julho', '/07/')
               .gsub('agosto', '/08/')
               .gsub('setembro', '/09/')
               .gsub('outubro', '/10/')
               .gsub('novembro', '/11/')
               .gsub('dezembro', '/12/')
               .gsub(/\s/,'')

    Date.strptime(date, '%d/%m/%Y').strftime("%Y-%m-%d")
  end
end
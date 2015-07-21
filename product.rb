require 'open-uri'
require_relative 'colors'

class Product
  attr_accessor :product_id, :name, :icon_path, :sku,
    :package_name, :store, :release_date, :last_update,
    :last_version, :app_type, :downloads, :updates, :revenue,
    :active, :id_trademark, :apikey_flurry, :apikey_flurry2, :observation

    TABLE = '`dashboard`.`appfigures_products`'
    COLUMNS = %w(product_id name icon_path sku package_name store release_date last_update last_version app_type downloads updates revenue active id_trademark apikey_flurry apikey_flurry2 observation)

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

    def self.table
      TABLE
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

    def crawl_data
      data = {
        package_name: self.package_name,
        icon_path: '',
        active: false,
        version: '',
        last_update: ''
      }

      begin
        url = "https://play.google.com/store/apps/details?id=#{package_name}"
        message = "Fetching extra data from #{url}"

        open(url) do |f|
          body = f.readlines.join(' ')
          data[:icon_path] = Product.image_url(body)
          data[:active] = data[:icon_path].to_s != ''
          data[:version] = Product.version(body)
          data[:last_update] = Product.updated_at(body)
        end

        puts "#{"[success]".green} #{message}"
      rescue => e
        puts "#{"[fail]".red} #{message}"
        puts e
      end

      data
    end

    def self.crawled_products
      @@crawled_products
    end

    def self.crawled_products=(value)
      @@crawled_products = value
    end


    private

    def fields
      [
        product_id, name, icon_path, sku, package_name, store, release_date, last_update,
        last_version, app_type, downloads, updates, revenue, active, id_trademark,
        apikey_flurry, apikey_flurry2, observation
      ]
    end

    def self.image_url(body)
      regex = /<img class=\"cover-image\" src=\"([\w\:\/\.\-\_\=]+)\" alt=\"Cover art\" aria-hidden=\"true\" itemprop=\"image\">/i
      body.scan(regex).flatten.first
    end

    def self.version(body)
      regex = /<div class=\"content\" itemprop=\"softwareVersion\">([\w\.\s\-]+)<\/div>/
      body.scan(regex).flatten.first.strip
    end

    def self.updated_at(body)
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
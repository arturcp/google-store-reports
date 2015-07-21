#require_relative 'icon'

class Product
  attr_accessor :product_id, :name, :icon_path, :sku,
    :package_name, :store, :release_date, :last_update,
    :last_version, :app_type, :downloads, :updates, :revenue,
    :active, :id_trademark, :apikey_flurry, :apikey_flurry2, :observation

    TABLE = '`dashboard`.`appfigures_products`'
    COLUMNS = %w(product_id name icon_path sku package_name store release_date last_update last_version app_type downloads updates revenue active id_trademark apikey_flurry apikey_flurry2 observation)

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
        else
          "'#{value}'"
        end
      end.join(', ')
    end

    def active?
      true
    end

    private

    def fields
      [
        product_id, name, icon_path, sku, package_name, store, release_date, last_update,
        last_version, app_type, downloads, updates, revenue, active, id_trademark,
        apikey_flurry, apikey_flurry2, observation
      ]
    end
end
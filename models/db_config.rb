require 'json'

class DBConfig
  def self.database
    @database ||= begin
      path = './config/config.json'
      database = 'dashboard'

      if File.exists?(path)
        file = File.open(path, "rb:UTF-8")
        database = JSON.parse(file.read)['database']
      end

      database
    end
  end
end
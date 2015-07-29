class FileWriter
  LOG_DIRECTORY = './logs'
  SQL_DIRECTORY = './sql'

  def self.log(filename, message)
    write_to_file(LOG_DIRECTORY, filename, '.log', [message])
  end

  def self.script(filename, queries)
    write_to_file(SQL_DIRECTORY, filename, '.sql', queries)
  end

  private

  def self.write_to_file(directory, filename, extension, queries)
    path = "#{directory}/#{OUTPUT_FILE_NAME}.#{extension}"

    unless File.directory?(directory)
      puts "#{"[Warning]".gray}: #{directory} did not exist and was created"
      FileUtils::mkdir_p(directory)
    end

    file_mode = File.exists?(path) ? 'a' : 'w'
    open(path, "#{file_mode}:UTF-8") { |f| f.write(queries.join("\n")) }
  end
end
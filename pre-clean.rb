require 'fileutils'

Dir.glob("data/**/*.mo").each do |file|
  File.delete(file) if File.exists? file
  FileUtils.rm_rf("data/locale")
end

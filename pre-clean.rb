require 'fileutils'

#Dir.glob("data/**/*.mo").each do |file|
#  File.delete(file)
  FileUtils.rm_rf("data/locale")
#end


require 'fileutils'

if config('disable-nls') == "no"
  podir = srcdir_root + "/po/"
  modir = srcdir_root + "/data/locale/%s/LC_MESSAGES/"

  Dir.glob("po/*/*.po") do |file|
    lang, basename = /po\/([\w\.]*)\/(.*)\.po/.match(file).to_a[1,2]
    FileUtils.mkdir_p modir % lang
    system("msgfmt #{podir}#{lang}/#{basename}.po -o #{modir}#{basename}.mo" % lang)
  end
end

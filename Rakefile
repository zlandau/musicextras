require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

desc "Default Task"
task :default => :test

desc "Run all tests"
task :testall => [:test, :testsites]

desc "Prepares for installation"
task :prepare do
  ruby "install.rb config"
  ruby "install.rb setup"
end

desc "Installs musicextras"
task :install do
  ruby "install.rb install"
end

desc "Cleans up temporary files"
task :clean do
  rm "config.save" rescue nil
  rm "InstalledFiles" rescue nil
end

desc "Cleans up completely"
task :distclean => [:clean, :clobber_rdoc]
task :distclean do
    rm Dir["*.tar.*"]
end

SITE_DIR = "#{ENV['HOME']}/public_html/hypa-src/musicextras/"
CODE_DIR = "#{ENV['HOME']}/code/archives/musicextras/"

desc "Sets up a package for release"
task :release => [:clean, :rdoc]
task :release do
  fail "Set VERSION environmental variable" unless ENV['VERSION']
  dir = "../musicextras-#{ENV['VERSION']}"
  sh "cp -r doc #{SITE_DIR}"
  sh "svn export . #{dir}"
  sh "svn log -r HEAD:1 -v > #{dir}/ChangeLog"
  sh "cp NEWS #{dir}/ChangeLog #{SITE_DIR}"
  cd dir
  sh "rake package"
  sh "cp #{dir}/musicextras-* #{SITE_DIR}"
  sh "mv #{dir}/musicextras-* #{CODE_DIR}"
  puts "Don't forget to make a copy of the release in subversion"
end

desc "Generate musicextras.pot"
task :genpot do
    input = "lib/musicextras/gui/glade-msg.c"
    fail "Must generate glade-msg.c with glade-2 first" unless File.exists?(input)
    system("xgettext -kN_ -o po/musicextras-gui.pot #{input}")
    puts "Generated file placed in po/musicextras-gui.pot"
end

desc "Packages up current release"
task :package => [:clean]
task :package do
  base = File.basename(Dir.pwd)
  sh "tar -zcf #{base}.tar.gz ../#{base} --exclude '*.tar.*'"
  sh "tar -jcf #{base}.tar.bz2 ../#{base} --exclude '*.tar.*'" 
  sh "gpg -sab #{base}.tar.gz"
  sh "gpg -sab #{base}.tar.bz2"
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 't/TC_*.rb'
  t.verbose = false
end

Rake::TestTask.new(:testsites) do |t|
  t.pattern = 't/musicsites/TC_*.rb'
  t.verbose = false
end

rd = Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = 'Musicextras'
  rdoc.rdoc_files.include('README', 'BUGS', 'COPYING', 'NEWS', 'THANKS', 'TODO')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

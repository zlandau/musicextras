require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

require "digest/md5"

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
  #sh "svn copy file:///home/kapheine/svn/musicextras/musicextras file:////home/kapheine/svn/musicextras/musicextras-#{ENV['VERSION']}"
  #sh "svn export . #{dir}"
  sh "darcs get . #{dir}"
  rm_rf "#{dir}/_darcs"
  sh "darcs changes >#{dir}/ChangeLog"
  sh "cp #{dir}/NEWS #{dir}/ChangeLog #{SITE_DIR}"
  cd dir
  sh "rake package"
  sh "cp ../musicextras-#{ENV['VERSION']}.* #{SITE_DIR}"
  sh "mv ../musicextras-#{ENV['VERSION']}.* #{CODE_DIR}"
  puts "Don't forget to make a copy of the release in darcs using: "
  puts "darcs tag musicextras-#{ENV['VERSION']}"
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
  #sh "tar -zcf #{base}.tar.gz ../#{base} --exclude '*.tar.*'"
  #sh "tar -jcf #{base}.tar.bz2 ../#{base} --exclude '*.tar.*'" 
  sh "tar -zcf ../#{base}.tar.gz ../#{base}"
  sh "tar -jcf ../#{base}.tar.bz2 ../#{base}" 
  sh "gpg -sab -o ../#{base}.tar.gz.asc ../#{base}.tar.gz"
  sh "gpg -sab -o ../#{base}.tar.bz2.asc ../#{base}.tar.bz2"
end

desc "Update the plugins list"
task :update_plugins do
  index = "/home/kapheine/public_html/hypa-src/musicextras/plugins/INDEX"
  File.open(index, "w") do |f|
    Dir["lib/musicextras/musicsites/*.rb"].each do |name|
      if name.match("_load_sites.rb") then next end
      md5 = Digest::MD5.hexdigest(File.read(name))
      f.write("#{md5} #{File.basename(name)}\n")
    end
  end
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

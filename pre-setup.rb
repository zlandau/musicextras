#!/usr/bin/ruby
#
# pre-setup.rb - populates _load_sites.rb and fills in CVERSIOS
#

# creating _load_sites.rb
list = Dir.glob(curr_srcdir + '/lib/musicextras/musicsites/*.rb').collect {|n| File.basename(n) }
list.delete('_load_sites.rb')
File.open(curr_srcdir + '/lib/musicextras/musicsites/_load_sites.rb', 'w') do |f|
  f.puts list.collect {|n| "require 'musicextras/musicsites/" + n + "'" }
end

# set Version
ma = curr_srcdir.match(/.*\/musicextras-([\d\s\w\.-]+)/)
version = ma ? ma[1] : "cvs"

tmpfile = File.open('musicextras.tmp', 'w')
File.open(curr_srcdir + '/lib/musicextras/mconfig.rb') do |f|
  
  while line = f.gets
    ma = line.match(/^(\s+)(Version|DATA_DIR)/)
    if ma
      if ma[2] == "Version"
	tmpfile.write "#{ma[1]}Version = \'#{version}\'\n"
      elsif ma[2] == "DATA_DIR"
	tmpfile.write "#{ma[1]}DATA_DIR = File.join('#{config('data-dir')}', 'musicextras')\n"
      end
    else
      tmpfile.write line
    end
  end
end
tmpfile.close

File.rename('musicextras.tmp', curr_srcdir + '/lib/musicextras/mconfig.rb')

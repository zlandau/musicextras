#!/usr/bin/ruby -w
#
# cache - Cache support
#
# version: $Id: cache.rb 316 2004-04-28 21:08:33Z kapheine $
#
# Copyright (C) 2003-2004 Zachary P. Landau <kapheine@hypa.net>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

require 'musicextras/mconfig'
require 'musicextras/debuggable'
require 'musicextras/utils'
require 'fileutils'
require 'timeout'
require 'yaml'

module MusicExtras

  ### Handles caching of data
  class Cache
    include Debuggable

    # Stores the directory where the caches are stored
    attr_reader :dir

    attr_reader :greylist_file

    # [+dir+] the directory to store cache data
    def initialize(dir=nil)
      @config = MConfig.instance
      @dir = dir || File.join(@config['basedir'], 'cache')
      @greylist_file = File.join(@dir, 'greylist.lst')
      @greylist_lock = File.join(@dir, '.greylist.lock')

      FileUtils.mkdir_p(@dir) 
      setup_greylist() unless defined? @@greylist
    end

    ### Removes the greylist file
    def clear_greylist
      FileUtils.rm_f @greylist_file
    end

    ### Removes entire cache dir
    def clear_cachedir
      FileUtils.rm_rf @dir
      FileUtils.mkdir_p @dir
    end

    ### Removes webcache dir
    def clear_webcache
      FileUtils.rm_rf File.join(@dir, 'webcache')
      FileUtils.mkdir_p File.join(@dir, 'webcache')
    end

    # Saves data in the cache, returning the file it was saved as
    # [+key+] What to save the cache as. Should be a directory structure, but
    #         all non-word chars will be removed, except the /s. For example:
    #         Tom Petty/Free Fallin' will be converted to TomPetty/FreeFallin
    # [+data+] The data to store
    def save(key, data)
      file = get_filename(key)
      debug_var { :file }

      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, 'w') do |f|
	f.write(data)
      end

      return file
    end

    # Loads data from the cache, returns the data or nil if it doesn't exist
    #
    # [+key+] What to save the cache as. Should be a directory structure, but
    #         all non-word chars will be removed, except the /s. For example:
    #         Tom Petty/Free Fallin' will be converted to TomPetty/FreeFallin
    def load(key)
      file = get_filename(key)
      debug_var { :file }

      if File.exists?(file)
	return File.new(file).read
      else
	return nil
      end
    end

    # Adds +key+ to greylist. Use get_filename() to generate key
    def add_to_greylist(key)
      file = get_filename(key, false)
      debug_var { :file }
      @@greylist[file] = Time.now

      save_greylist
    end

    # Remove +key+ from greylist. Use get_filename() to generate key
    def remove_from_greylist(key)
        file = get_filename(key, false)
        debug_var { :file }
        @@greylist.delete(key)

        save_greylist
    end

    # Checks to see if a key is in the greylist
    def greylisted?(key)
      entry = @@greylist[get_filename(key, false)]

      if !@config['greylist_timeout']
	return entry
      else
	return entry && entry+@config['greylist_timeout'] > Time.now
      end
    end

    # Writes greylist to file
    def save_greylist
      greylist_lock do 
	File.open(@greylist_file, 'w') do |f|
	  YAML.dump(@@greylist, f)
	end
      end
    end


    ### Reads the greylist from the greylist file or creates a new one
    def setup_greylist()
      if File.exists?(@greylist_file)
	greylist_lock do
	  File.open(@greylist_file, 'r') do |f|
	    begin
	      @@greylist = YAML.load(f) || Hash.new
	    rescue ArgumentError
	      @@greylist = Hash.new
	    end
	  end
	end
      else
	@@greylist = Hash.new
      end

      # If the old greylist format was loaded, convert to the new format
      if @@greylist.class == Array
	old_greylist = @@greylist
	@@greylist = {}
	old_greylist.each { |x| @@greylist[x] = Time.now }
      end
    end

    ### Handles greylist locking for the given block
    ### [+block+] Code that needs exclusive access to the greylist
    def greylist_lock(&block)
	begin
	  timeout(10) do
	    while File.exists?(@greylist_lock)
	      sleep(0.25)
	    end
	  end
	rescue Timeout::Error
	  # 10 seconds to read the file? doubtful. we'll continue.
	end

        begin
          File.open(@greylist_lock, 'w') { block.call }
          File.delete(@greylist_lock)
        rescue Errno::ENOENT
          # ignore
        end
    end


    # Returns the filename for a given key
    # [+key+] The key to get the filename from
    # [+include_path+] If true, will include full path to file. Defaults to true.
    def get_filename(key, include_path=true)

      # Make sure to preserve extension, if there is one
      if key.index('.')
	base = key.split('.')[0..-2].to_s
	extension = '.' + key.split('.')[-1]
      else
	base = key
	extension = ''
      end

      path = File.basename(base, extension)

      # Split up dirs, mangle their names, and put them back together
      dirs = []
      base.split('/').each do |dir|
	dirs << dir.mangle
      end
      full_dir = dirs.join('/') + "#{extension}"

      if include_path
	return File.join(@dir, full_dir)
      else
	return full_dir
      end
    end

  end

end

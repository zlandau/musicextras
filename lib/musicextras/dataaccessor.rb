#!/usr/bin/ruby -w
#
# dataaccessor - DataAccessor object. Objects should inherit from this when
#                they want to get data from plugins
#
# version: $Id: dataaccessor.rb 324 2004-05-21 13:15:11Z kapheine $
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

require 'musicextras/accessordata'
require 'musicextras/cache'
require 'musicextras/mconfig'
require 'musicextras/debuggable'
require 'thread'

module MusicExtras

  ### DataAccessor class provides the interface between data classes and plugins.
  ### It allows plugins to register with the class. When someone calls a method
  ### of the class that doesn't exist, the registered plugins are checked for
  ### implementations of the method. Whatever (non-nil) data returned from a
  ### plugin is used
  class DataAccessor
    include Debuggable

    # Raised when no plugins are loaded to handle a fetch method
    class AccessorNotImplemented < StandardError; end

    # Holds the AccessorDatas for the plugins. Key is accessor class
    # (eg: [Song]->Array_of_Accessor_Datas
    @@plugins = Hash.new

    # Setups up cache. Data Accessors should be sure to call super
    # [+use_cache+] set to false if you don't want to use the cache
    def initialize(use_cache=nil)
      @config = MConfig.instance
      @use_cache = use_cache || @config['use_cache']

      # initialize it even if we don't use cache, because we use some of
      # its methods
      @cache = Cache.new
    end

    ### This method should be called in the initialize() for each plugin.
    ### It should be called one time per accessor method.
    ### [+plugin+] The instance of the plugin (should pass in 'self')
    ### [+accessor+] The method that should be called to fetch the data
    ### [+cache_path+] The cache path to load and save data (see Cache)
    def self.register_plugin(plugin, accessor, cache_path)

      @@plugins[self.to_s] = Array.new unless @@plugins.has_key?(self.to_s)
      @@plugins[self.to_s] << AccessorData.new(plugin, accessor, cache_path)
    end

    ### Returns a list of available accessors as Symbols
    def self.accessors
      return nil unless @@plugins[self.to_s]
      return @@plugins[self.to_s].collect { |p| p.accessor }.uniq
    end

    ### Whenever a method doesn't exist, we check if there are any registered
    ### accessors to handle it.
    ### Raises AccessorNotImplemented when none of the registred plugins
    ### implement the method
    def method_missing(meth)
      accessors = get_accessors(meth)
      unless accessors
	raise AccessorNotImplemented, "No plugin loaded for \`#{meth.id2name}\' in #{self.class}"
      end

      return load_data(accessors)
    end

    ### Returns all accessors that are associated with this method
    ### [+meth+] The method we want accessors for
    def get_accessors(meth)
      accessors = []

      if @@plugins.has_key?(self.class.to_s)
	@@plugins[self.class.to_s].each do |a|
	  if meth == a.accessor
	    accessors << a
	  end
	end
      end

      return accessors.length == 0 ? nil : accessors
    end

    ### Data is retrieved using the accessor information. First the cache
    ### is checked. If that fails, the accessor fetch methods are called.
    ### If data is retrieved, it is saved in the cache and returned. Otherwise
    ### nil is returned
    def load_data(accessors)
      debug_enter()
      fail 'Cache was not initialized in DataAccessor' if @use_cache == true && @cache.nil?
      cache_path = cache_values(accessors[0].cache_path)

      data = nil

      # Try loading from cache
      if @use_cache && (data = @cache.load(cache_path))
          @cache.remove_from_greylist(cache_path)
          debug(1, "Loading data from #{@cache.get_filename(cache_path, false)}")
          return data
      end

      # Return if greylist says we can't get data
      return nil if @cache.greylisted?(cache_path) if @use_cache

      # Anotherwise, try to get it from the plugin sites
      data = retrieve_data(accessors)

      # Save the data to cache if we got it
      if data
	@cache.save(cache_path, data) if @use_cache
        debug(1, "Saving data to #{@cache.get_filename(cache_path, false)}")
	return data
      else
	@cache.add_to_greylist(cache_path) if @use_cache
        debug(1, "Adding #{@cache.get_filename(cache_path, false)} to greylist")
	return nil
      end
    end

    ## Determines the filename the data should be cached under
    ## [+name+] The accessor name (ie: :lyrics, :image, etc)
    ## Returns nil if no accessors are found
    def cached_as(name)
      accessors = get_accessors(name)
      return nil unless accessors

      # We'll assume that the path for the first accessor is the same as the rest
      return @cache.get_filename(cache_values(accessors[0].cache_path))
    end

    ### Replaces tags with correct values. Each data accessor should implement
    ### this. Eg: Song would replace {TITLE} with the correct title
    ### Return the new string
    def cache_values(str)
      return str
    end

    NO_DATA = -1 # :nodoc:

    ### Takes accessors and tries to fetch the data. 
    ### Whichever returns (nonnil) data first wins the prize of being returned.
    ### Nil is returned it none of the accessors returned valid data. 
    def retrieve_data( accessors ) # :nodoc:
      debug_enter()
      mutex = Mutex.new
      
      data = NO_DATA		# the data retrieved
      accessor_data = nil	# the accessor data for the plugin that 'won'

      threads = []

      if @config && @config['debug_level'] && @config['debug_level'] > 1
	Thread.abort_on_exception = true
      end
      
      accessors.each do |a|
	
	threads << Thread.new(a) do |a|
	  begin
	    Thread.current[:connection_error] = nil
	    tmp_data = a.run(self)
	    mutex.synchronize do 
	      if ( (data == NO_DATA) && (tmp_data) )
		data = tmp_data
		accessor_data = a
	      end
	    end
	  rescue SocketError => e
	    Thread.current[:connection_error] = e
	  rescue => e
	    debug(1, "#{a.plugin.name}.#{a.accessor} failed: #{e.class}: #{e}")
	    if @config && @config['debug_level'] && @config['debug_level'] > 1
	      raise
	    end
	  end
	end

      end

      # XXX: How can I do this without polling?
      loop do
	alive = false

	sleep(0.1)

	# don't give up until all threads are done
	threads.each do |thread|
	  alive = true if thread.alive?
	end

	# if we got data, return immediately
	unless data == NO_DATA
	  debug(1, "retrieve_data successful [#{accessor_data.plugin.name}:#{accessor_data.accessor}]")
	  return data
	end

	unless alive
	  # See if they all got connection errors
	  error = true
	  threads.each { |t| error = false if t[:connection_error] == nil }
	  if error
	    raise threads[0][:connection_error]
	  end

	  debug(1, "retrieve_data unsuccessful")
	  return nil
	end

      end
    end


  end

end

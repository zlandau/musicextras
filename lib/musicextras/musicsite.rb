#!/usr/bin/ruby -w
#
# musicsite - Abstract MusicSite class
#
# version: $Id: musicsite.rb 330 2004-07-07 22:46:21Z kapheine $
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
require 'musicextras/utils'
require 'digest/md5'
require 'net/http'
require 'fileutils'

module MusicExtras

  # == Writing musicsite plugins
  #
  # Adding new site plugins should be fairly straight forward. I'll use parts of
  # the AllMusic plugin as an example. 
  #
  #   class AllMusic < MusicSite
  #
  #   NAME = 'AllMusic'
  #   URL = 'www.allmusic.com'
  #   DESCRIPTION = 'Lots of information and images for many artists'
  #
  #   def initialize
  #     super(NAME, URL)
  #
  #     Artist::register_plugin(self, :image, '{ARTIST}/{ARTIST}.img')
  #     Album::register_plugin(self, :cover, '{ARTIST}/covers/{ALBUM}.img')
  #   end
  #
  # The first parameter to super should be a meaningful name for the plugin
  # (without spaces). The second parameter should be the base url for the site.
  # NAME should be a meaningful name for the plugin (without spaces). URL
  # should be the base url for the site. DESCRIPTION should be a brief description
  # of what the site provides (and the language for the lyrics, if not in English)
  #
  # The last two lines register a method with an aggregator. So once the
  # first line is registered, the image method in your plugin will be called
  # when artist.image is called. So your image method should return the binary
  # data for the image. The third line is where the information is cached on
  # the filesystem. See the Artist.cache_values, Album.cache_values, and
  # Song.cache_values for the available {} variables. You may make up any
  # cache path you want, but it should make sense, and stay consistent with
  # the other plugins.
  #
  # To get your plugin registered with the list of other plugins, make sure to
  # call the class method register() somewhere outside of a method definition.
  # To have your plugin getloaded automatically, add it to
  # musicextras/musicsites/_load_sites.rb
  #
  # Use the available plugins as an example. There are some helper functions
  # available to you from inheriting this class so check out the code below.
  #
  # NOTE: Plugins should return text as UTF-8. extract_text() will do the 
  # conversion for you, but you must do it yourself if you do not call
  # extract_text(). You may use String#to_utf8 for this.
  #
  class MusicSite
    include Debuggable

    class InvalidPlugin < StandardError
        def initialize(msg)
            @message = msg
        end

        def to_s
            "Plugin does not exist: #{@message}"
        end
    end

    # Stores the name of the plugin
    attr_reader :name

    # Store a description for the plugin
    attr_reader :description

    # Stores the url of page for the plugin
    attr_reader :url

    # Useragents you can use if your plugin needs it
    USERAGENTS = {
        'Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2.1) Gecko/20030225',
        'Opera'   => 'Opera/6.0 (Linux 2.4.18 i686; U)  [en]',
        'Lynx'    => 'Lynx/2.8.4dev.16 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6-beta3'
    }

    # Cache paths that plugins should use
    CACHE_PATH = {
        'lyrics'       => '{ARTIST}/{TITLE}.lyrics',
        'synced_lyrics' => '{ARTIST}/{TITLE}.lrc',
        'biography'    => '{ARTIST}/biography.txt',
        'artist_image' => '{ARTIST}/{ARTIST}.img',
        'years_active' => '{ARTIST}/years_active.txt',
        'album_cover'  => '{ARTIST}/covers/{ALBUM}.img',
        'album_review' => '{ARTIST}/reviews/{ALBUM}.txt',
	'album_tracks' => '{ARTIST}/tracks/{ALBUM}.txt',
	'album_year'   => '{ARTIST}/years/{ALBUM}.txt'	
    }

    NAME = "RedefineNAME"
    URL = "RedefineURL"
    DESCRIPTION = "RedefineDESCRIPTION"

    ### Creates a new music site. All plugins should call super so this is ran.
    ### [+name+] A meaningful name for the site (without spaces)
    ### [+url+] The base url of the site (eg: www.allmusic.com)
    def initialize(name, url)
      @name = name
      @url = url
      @config = MConfig.instance
    end

    ### Register plugin with list of available plugins
    def self.register
        @@plugins = [] unless defined? @@plugins

        @@plugins << self.to_s.split('::')[1]
    end

    ### Returns list of available plugins
    def self.plugins
        (defined? @@plugins) ? @@plugins : []
    end

    ### Activates plugins. Optionally, +plugins+ can specify
    ### an Array of plugin names to be loaded. This can be retrieved
    ### from MusicSite.plugins
    def self.activate_plugins(plugins=self.plugins)
        plugins.each do |x|
            begin
                x = MusicExtras.const_get(x.to_s)
                x.new
            rescue NameError
                raise InvalidPlugin.new(x)
            end
        end
    end

    def self.run_tests
      @@plugins.each do |t|
	plugin = MusicExtras.const_get(t.to_s)
	results = plugin.new.test
	yield([plugin.to_s.split('::')[1], results[0], results[1]])
      end
    end

    ### Prints in the following format: 'MusicSite: (url)'
    def to_s
      "#{@name} [#{@url}]"
    end

    ### Compares two strings using String.mangle
    ### [+str1+] the first String
    ### [+str2+] the second String
    ### [+remove_pronouns+] set to true if pronouns should be removed. defaults to false.
    ### Returns true or false
    def match?(str1, str2, remove_pronouns=false)
      return str1.mangle(remove_pronouns) == str2.mangle(remove_pronouns)
    end

    ### Extracts text from an html page and returns it as utf-8 without the html tags.
    ### [+page+] A String containing the html
    ### [+regexp+] A Regexp with only one (), that should contain the text
    ###            Make sure to include /m at the end for multiple lines
    ### [+encoding+] Encoding of text. Defaults to iso-8859-1
    def extract_text(page, regexp, encoding="iso-8859-1")
      page.scan(regexp) do |line|
        return line.to_s.strip_html.to_utf8(encoding)
      end

      debug(1, "regexp failed")
      return nil
    end

    CACHE_LIFE = 60*60*24*7

    ### Downloads a page, given a url. Returns the contents, or nil if
    ### there was a problem. Uses a 7 day file cache.
    ### [+url+] url to download (@url should contain the hostname)
    ### [+post+] post data to send (defaults to nil)
    ### [+useragent+] optional useragent string to pass to server
    def fetch_page(url, post=nil, agent=nil)
      # XXX: implement redirect handling
      if (url =~ /^http:/)
	uri = url
      else
	uri = "http://#{@url}#{url}"
      end

      debug_var { :uri }

      params = {}
      if agent
        params = {"User-Agent" => agent}
      end

      page_cache = File.join(@config['basedir'], 'cache', 'webcache')
      FileUtils.mkdir_p(page_cache) unless File.exists?(page_cache)
      cache_file = File.join(page_cache, Digest::MD5.hexdigest("#{uri}#{agent}#{post}"))
    
      begin
	uri_parse = URI.parse(uri)
	host = uri_parse.host
	path = uri_parse.path
	path = path == "" ? "/" : path
	path += "?#{uri_parse.query}" if uri_parse.query
      rescue URI::InvalidURIError
	debug_var { :uri }
	host = uri.match(/http:\/\/([^\/]*)\//)[1]
	path = uri.match(/http:\/\/[^\/]*(\/.*)/)[1]
	path = path == "" ? "/" : path
      end

      begin
	if File.exists?(cache_file) and
	  Time.now - File.mtime(cache_file) < CACHE_LIFE 
	  data = File.open(cache_file).read
	else
          response = nil
          verbose = $VERBOSE
          $VERBOSE = false
          conn = nil
          if ENV['HTTP_PROXY']
            uri_parse = URI.parse(ENV['HTTP_PROXY'])
            conn = Net::HTTP.Proxy(uri_parse.host, uri_parse.port || 8080)
          else
            conn = Net::HTTP
          end
	  conn.start(host) do |http|
	    http.read_timeout = @config['timeout']
            unless post
              response = http.get(path, params)
            else
	      params["Content-type"] = "application/x-www-form-urlencoded"
              response = http.post(path, post, params)
            end
	    data = response.body
	    File.open(cache_file, "w") { |f| f.write(data) }
	  end
          $VERBOSE = verbose
	end
      rescue SocketError => error
	if error.message =~ /^getaddrinfo/
	  raise
	end
      rescue => error
	debug(1, "error retrieving #{uri}: #{error}")
      end

      data
    end
  
    ### Returns a string of the form: Source: SiteName [URL]
    def source
      "\n\nSource: #{self.to_s}\n"
    end

    ## If plugin passes, returns an array of [true, []]
    ## If plugin failes, returns an array of [false, msgs] where msgs is an
    ## array of strings describing the failed tests
    ## If plugin doesn't implement tests, don't override this
    def test
      [nil, []]
    end

    ## Search config['updateurl'] remote site for any plugin updates,
    ## saving the updates to the search path if any updates are found
    ## Returns the number of plugins updated
    def self.update(verbose=false)
      num_updated = 0
      config = MConfig.instance
      uri_parse = URI.parse(File.join(config['updateurl'], 'INDEX'))
      host = uri_parse.host
      path = uri_parse.path
      data = nil
      if ENV['HTTP_PROXY']
        uri_parse = URI.parse(ENV['HTTP_PROXY'])
        conn = Net::HTTP.Proxy(uri_parse.host, uri_parse.port || 8080)
      else
        conn = Net::HTTP
      end
      conn.start(host) do |http|
        http.read_timeout = config['timeout']
        response = http.get(path)
        data = response.body
      end

      sitebase = File.join(File.dirname(__FILE__), "musicsites")
      data.scan(/(.*?) (.*?)\n/m) do |md5, file|
        path = File.find_in_path("musicextras/musicsites/#{file}", $LOAD_PATH)
        #puts("md5: #{md5} #{Digest::MD5.hexdigest(File.read(path))} #{path}")
        if Digest::MD5.hexdigest(File.read(path)) != md5 
          puts "Updating #{file}..." if verbose
          url = File.join(config['updateurl'], file)
          conn.start(host) do |http|
            http.read_timeout = config['timeout']
            response = http.get(url)
            data = response.body
            writepath = File.join(config['basedir'], 'musicextras', 'musicsites')
            FileUtils.mkdir_p(File.join(writepath))
            File.open(File.join(writepath, file), "w") { |f| f.write(data) }
            num_updated += 1
          end
        end
      end
      
      num_updated
    end
  end

end

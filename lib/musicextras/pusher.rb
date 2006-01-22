#!/usr/bin/ruby18 -w
#
# pusher - handles command line arguments, retrieving data, and sending
#	   it out
#
# version: $Id: pusher.rb 325 2004-07-05 12:52:01Z kapheine $
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
$LOAD_PATH.unshift(MusicExtras::MConfig.instance['basedir'])
require 'musicextras/musicsites/_load_sites'
require 'musicextras/musicsite'
require 'musicextras/album'
require 'musicextras/artist'
require 'musicextras/song'
require 'musicextras/cache'
require 'musicextras/guicontrol'
require 'musicextras/debuggable'
require 'base64'
require 'optparse'
require 'ostruct'
require 'rexml/document'
require 'fileutils'

begin
    require 'gettext'
    include GetText
    bindtextdomain('musicextras')
rescue LoadError, NameError
    def _(txt)
        txt
    end
end

module MusicExtras
  
  ### This class handles input from the user, retrieves the data,
  ### and sends it off to the GUI.
  class Pusher
    include Debuggable

    PROGNAME = File.basename($0)

    ### Parses arguments, +args+ defaults to ARGV
    def initialize(args=ARGV)
      @config = MConfig.instance

      Debuggable::setup()
      debug(1, "Running as: #{$PROGRAM_NAME} #{ARGV.join(' ')}")

      @valid_fetchers = private_methods.collect do |x|
          ma = x.match(/handle_(.*)/)
          ma ? ma[1] : nil
      end.compact

      # May specify the order things are fetched in. Anything not listed
      # here will go in any order after those items in the list
      @fetcher_order = %w(song_info lyrics synced_lyrics artist_image album_cover album_year)

      if args.length == 0
        $stderr.puts "%s: musicextras <options>" % _("Usage")
        exit 1
      else
        parse_options(args)
      end

      if x = invalid_fetcher(@options.fetchers)
          $stderr.puts _("Invalid fetcher: #{x}")
          exit 1
      end

      @output = STDOUT

      if @options.run_tests == true
	exit_code = 0
	puts "Test results:"
	@options.plugins.each do |plugin|
	  begin
	    passed, msg = MusicExtras.const_get(plugin).new.test()
	  rescue Exception => e
	    passed = false
	    msg = [e.message]
	  end
	  if passed
	    info = "passed"
	  elsif passed == false
	    info = "failed: #{msg.join(', ')}"
	    exit_code = 10
	  elsif passed == nil
	    info = "not implemented"
	  end

	  puts "\t* %-20s [%s]" % [plugin, info]
	end
	exit exit_code
      end

      if @options.quit_after_parse == true
	exit 0
      end
    end

    ### Retrieves and outputs the data
    def output
      begin
        hostname, port = @config['gui_host'].split(':')
        port ||= ::Config::DEFAULT_GUI_PORT

	begin
	  @output = TCPSocket.new(hostname, port) if @options.gui
	rescue Errno::ECONNREFUSED, Errno::ENOENT
	  $stderr.puts _("Connection refused. Make sure musicextras-gui is running on %s:%s.") % [hostname, port]
	  exit 1
	end

	begin
	  xml_header()
	  retrieve_data()
	  xml_footer()

	rescue SocketError => e
	  STDERR.puts "Connection error on all attempts: #{e.message}"
	  exit 6
	ensure
	  @output.close if @options.gui
	end

      rescue Errno::EPIPE
	# Another client probably connected, so just silently quit
      end

      debug(1, "Program Exiting")
    end

    private

    ### Returns version information
    def version()
      "#{PROGNAME} #{Version}\n" + 
      "Copyright (C) 2004 Zachary P. Landau"
    end

    ### setup default debugging vars
    def setup_debug
      Debuggable::setup()
    end

    ### Parse the options, returning a hash of options
    def parse_options(args)
      @options = OpenStruct.new
      @options.gui = true
      @options.verbose = @config['verbose'] || false
      @options.fetchers = @config['fetchers'] || @valid_fetchers
      @options.plugins = @config['plugins'] || MusicSite::plugins
      @options.quit_after_parse = false

      @song = nil

      opts = OptionParser.new do |opts|
        opts.banner = version()
        opts.separator ""
        opts.separator "%s: musicextras <options>" % _("Usage")

        opts.on("-a", "--artist NAME", _("specify artist")) do |o|
          @options.artist = artist_pre_regex(o.to_utf8)
        end
        opts.on("-l", "--album NAME", _("specify album")) do |o|
          @options.album = album_pre_regex(o.to_utf8)
        end
        opts.on("-t", "--title NAME", _("specify song title")) do |o|
          @options.title = o.to_utf8
        end
        opts.on("-f", "--file FILE", _("specify file to read mp3 tag from")) do |o|
          begin
            @song = Song.from_mp3_tag(o)
            @options.title = @song.title.to_utf8
            @options.artist = artist_pre_regex(@song.artist.name.to_utf8)
            if @song.album
              @options.album = album_pre_regex(@song.album.title.to_utf8)
              @song.artist.name = artist_pre_regex(@options.artist)
            else
              @options.album = ""
            end
          rescue Errno::ENOENT, Errno::EACCES => e
            $stderr.puts "#{$PROGRAM_NAME}: #{e}"
            exit 5
          rescue Song::InvalidTagException => e
            $stderr.puts "#{$PROGRAM_NAME}: #{o}: #{e}"
            exit 5
          end
        end

        opts.separator ""

        opts.on("-g", "--gui [hostname[:port]]", _("display information using gui (default)")) do |o|
          @options.gui = true
          @config['gui_host'] = o if o
        end
        opts.on("-s", "--stdout", _("display information to stdout")) do
          @options.gui = false
          @output = STDOUT
        end
        opts.on("-v", "--verbose", _("be verbose")) do
          @options.verbose = true
        end

        opts.separator ""

        opts.on("-i", "--include LIST", Array,
                _("comma-separated list of fetchers to use")) do |o|
          @options.fetchers = o
        end
        opts.on("-x", "--exclude LIST", Array,
                _("comma-separated list of fetchers to exclude")) do |o|
          @options.fetchers -= o
        end
        opts.on("-L", "--list-fetchers", _("display available fetchers")) do
          puts _("Valid fetchers:")
	  @valid_fetchers.sort_by do |f|
	    @fetcher_order.index(f) || 99999
	  end.each do |x|
	    puts "\t* #{x}"
	  end
          exit 0
        end
        opts.on("-I", "--include-plugins LIST", Array,
                _("comma-separated list of plugins to use")) do |o|
          @options.plugins = o
        end
        opts.on("-X", "--exclude-plugins LIST", Array,
                _("comma-separated list of plugins to exclude")) do |o|
          @options.plugins -= o
        end
        opts.on("-P", "--list-plugins", _("display available plugins")) do
          puts _("Valid plugins:")
          MusicSite::plugins.each do |x|
            plugin = MusicExtras.const_get(x)
            name = "#{x} [#{plugin::URL}]"
            puts "  * %-35s %s" % [name, plugin::DESCRIPTION]
          end
          exit 0
        end

        opts.separator ""

        opts.on("-c", "--[no-]cache", _("[don't] use cache")) do |o|
          @config['use_cache'] = o
        end
        opts.on("-C", "--clear-greylist", _("clears the greylist and exits")) do
	  puts "Clearing greylist..."
          cache = Cache.new
          cache.clear_greylist
	  @options.quit_after_parse = true
        end
        opts.on("", "--clear-cache", _("removes all data in cache directory")) do
	  puts "Clearing cache..."
          cache = Cache.new
          cache.clear_cachedir
	  @options.quit_after_parse = true
        end
        opts.on("", "--clear-webcache", _("clears cached web data")) do
	  puts "Clearing webcache..."
          cache = Cache.new
          cache.clear_webcache
	  @options.quit_after_parse = true
        end

        opts.on("-d", "--debug-level=[LEVEL]", Integer, _("sets debug level (defaults to 3)")) do |o|
          @config['debug_level'] = o || 3
          file = File.join(@config['basedir'], "debug.log")
          @config['debug_io'] = File.open(file, "a")
          @config['debug_io'].sync = true
        end

	opts.on("-T", "--test", _("runs tests to see if plugins are working")) do
	  @options.run_tests = true
	end

        opts.on("-u", "--update", _("update the plugins")) do
          num_updated = MusicSite.update(@options.verbose)
          puts "#{num_updated} plugin(s) updated" if @options.verbose
          if num_updated > 0
            exit 1
          else
            exit 0
          end
        end

        opts.on("-h", "--help", _("displays this usage")) do
          puts opts
          exit 0
        end
        opts.on("-V", "--version", _("displays version information")) do
          puts version()
          exit 0
        end
      end

      begin
        opts.parse!(args)
      rescue OptionParser::InvalidOption => e
        $stderr.puts _("%s: invalid option -- %s") % [PROGNAME, e.args[0]]
        exit 1
      end

      @options
    end

    ### Check if +fetchers+ have a corresponding handle_* method,
    ### returning the first invalid one or nil if all are valid
    def invalid_fetcher(fetchers)
        fetchers.each do |x|
            return x unless @valid_fetchers.include? x
        end
        
        nil
    end

    ### Uses the command line options to create appropriate Song, Album, Artist,
    ### etc. Sends the tags to the queue as they are retrieved
    def retrieve_data
      clear_old_tags if @options.gui

      MusicSite::activate_plugins(@options.plugins)

      @options.fetchers = @options.fetchers.sort_by do |f|
          @fetcher_order.index(f) || 99999
      end

      @options.fetchers.each do |x|
          send("handle_#{x}")
      end

      output_tag('STATUS', '') if @options.gui
    end

    # Send empty tags to clear out old info
    def clear_old_tags
      output_tag('LYRICS', '')
      output_tag('LYRICS_FILE', '')
      output_tag('ARTIST_IMAGE', nil)
      output_tag('ALBUM_COVER', nil)
      output_tag('TITLE', '')
      output_tag('ARTIST', '')
      output_tag('ALBUM', '')
      output_tag('BIOGRAPHY', '')
      output_tag('YEARS_ACTIVE', '')
      output_tag('ALBUM_REVIEW', '')
      output_tag('STATUS', '')
    end

    ### Applies @config['artist_pre_regex'] regex to given parameter,
    ### returning the new version
    def artist_pre_regex(artist)
      regexp_list(artist, @config['artist_pre_regex']) do |a|
	return a
      end
      
      artist
    end

    ### Applies @config['album_pre_regex'] regex to given parameter,
    ### returning the new version
    def album_pre_regex(album)
      regexp_list(album, @config['album_pre_regex']) do |a|
        return a
      end

      album
    end

    ### Takes an array of [regexp, sub] pairs to apply to a string, yielding
    ### each one
    ### [+str+] The string to apply the regexp to
    ### [+list+] List of [regexp, sub] pairs
    def regexp_list(str, list)
      list.each do |regex|
	sub = str.sub(regex[0], regex[1])
	yield sub if sub != str
      end
    end

    ### Sends LYRICS => Lyrics_Data tag to queue if lyrics are found,
    ### nil otherwise
    def handle_lyrics
      output_tag('STATUS', _('Retrieving lyrics..')) if @options.gui

      unless @song
	if @options.title && @options.artist
	  @song = Song.new(@options.title, @options.artist)
	else
          info _('Notice: not retrieving lyrics (missing title or artist)')
	  return
	end
      end

      if @song
	@options.lyrics_artist = @options.artist
	begin
	  lyrics = @song.lyrics

	  # If lyrics aren't found, start applying regex to the artist
	  unless lyrics
	    regexp_list(@options.artist, @config['artist_cond_regex'] ) do |a|
	      lyrics = Song.new(@options.title, a).lyrics
	      if lyrics
		@options.lyrics_artist = a
		break
	      end
	    end
	  end
	rescue DataAccessor::AccessorNotImplemented
	  lyrics = _('No lyrics plugin loaded.')
	end
	lyrics = _('No lyrics found.') if lyrics.nil?
      end

      output_tag('LYRICS', lyrics)
      output_tag('LYRICS_FILE', Song.new(@options.title, @options.lyrics_artist).cached_as(:lyrics))
    end
  
    ### Sends SYNCED_LYRICS => SyncedLyrics_Data tag to queue if lyrics are found,
    ### nil otherwise
    def handle_synced_lyrics
      output_tag('STATUS', _('Retrieving synced lyrics..')) if @options.gui

      unless @song
        if @options.title && @options.artist
          @song = Song.new(@options.title, @options.artist)
        else
          info _('Notice: not retrieving synced lyrics (missing title or artist)')
          return
        end
      end

      if @song
        @options.lyrics_artist = @options.artist
        begin
          lyrics = @song.synced_lyrics

          # If lyrics aren't found, start applying regex to the artist
          unless lyrics
            regexp_list(@options.artist, @config['artist_cond_regex'] ) do |a|
              lyrics = Song.new(@options.title, a).synced_lyrics
              if lyrics
                @options.lyrics_artist = a
                break
              end
            end
          end
        rescue DataAccessor::AccessorNotImplemented
          lyrics = _('No synced lyrics plugin loaded.')
        end
        lyrics = _('No synced lyrics found.') if lyrics.nil?
      end

      output_tag('SYNCED_LYRICS', lyrics)
      output_tag('SYNCED_LYRICS_FILE', Song.new(@options.title, @options.lyrics_artist).cached_as(:synced_lyrics))
    end

    ### Sends ARTIST_IMAGE => Binary_Data tag to queue if image is found,
    ### nil otherwise
    def handle_artist_image
      output_tag('STATUS', _('Retrieving artist image..')) if @options.gui

      if @options.artist
	artist = Artist.new(@options.artist)
	begin
	  image = artist.image

	  unless image
	    regexp_list(@options.artist, @config['artist_cond_regex'] ) do |a|
	      image = Artist.new(a).image
	      break if image
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  image = nil
	end
      else
        info _('Notice: not retrieving artist image (missing artist)')
	image = nil
      end

      output_tag('ARTIST_IMAGE', image, true)
    end

    ### Sends ALBUM_COVER => Binary_Data tag to queue if cover is found,
    ### nil otherwise
    def handle_album_cover
      output_tag('STATUS', _('Retrieving album cover..')) if @options.gui

      if @options.album && @options.artist
	album = Album.new(@options.album, @options.artist)

	begin
	  cover = album.cover

	  unless cover
	    regexp_list(@options.artist, @config['artist_cond_regex'] ) do |a|
	      cover = Album.new(@options.album, a).cover
	      break if cover
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  cover = nil
	end
      else
        info _('Notice: not retrieving album cover (missing album or artist)')
	cover = nil
      end

      output_tag('ALBUM_COVER', cover, true)
    end

    ### Sends ALBUM_TRACKS => Text tag to queue if tracks are found,
    ### nil otherwise
    def handle_album_tracks
      output_tag('STATUS', _('Retrieving album tracks..')) if @options.gui

      if @options.album && @options.artist
	album = Album.new(@options.album, @options.artist)

	begin
	  tracks = album.tracks

	  unless tracks
	    regexp_list(@options.artist, @config['artist_cond_regex']) do |a|
	      tracks = Album.new(@options.album, a).tracks
	      break if tracks
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  tracks = nil
	end

	tracks = _('No tracks found.') if tracks.nil?
      else
	info _('Notice: not retrieving album tracks (missing album or artist)')
	tracks = nil
      end

      output_tag('ALBUM_TRACKS', tracks, false)
    end

    ### Sends ALBUM_YEAR => Text tag to queue if found, nil otherwise
    def handle_album_year
      output_tag('STATUS', _('Retrieving album year..')) if @options.gui

      if @options.album && @options.artist
	album = Album.new(@options.album, @options.artist)

	begin
	  year = album.year

	  unless year
	    regexp_list(@options.artist, @config['artist_cond_regex']) do |a|
	      year = Album.new(@options.album, a).year
	      break if year
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  year = nil
	end

      else
	info _('Notice: not retrieving album year (missing album or artist)')
	year = nil
      end

      output_tag('ALBUM_YEAR', year, false)
    end

    ### Sends BIOGRAPHY => Bio_Data if found
    def handle_biography
      output_tag('STATUS', _('Retrieving biography..')) if @options.gui

      if @options.artist 
	artist = Artist.new(@options.artist)

	begin
	  bio = artist.biography

	  unless bio
	    regexp_list(@options.artist, @config['artist_cond_regex']) do |a|
	      bio = Artist.new(a).biography
	      break if bio
	    end
	  end
	rescue DataAccessor::AccessorNotImplemented
	  bio = nil
	end

	bio = _('No biography found.') if bio.nil?
      else
	info _('Notice: not retrieving biography (missing artist)')
      end

      output_tag('BIOGRAPHY', bio, false)
    end

    ### Sends ALBUM_REVIEW => data if found
    def handle_album_review
      output_tag('STATUS', _('Retrieving album review..')) if @options.gui

      if @options.album && @options.artist
	album = Album.new(@options.album, @options.artist)

	begin
	  review = album.review

	  unless review
	    regexp_list(@options.artist, @config['artist_cond_regex'] ) do |a|
	      review = Album.new(@options.album, a).review
	      break if review
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  review = nil
	end

	review = _('No album review found.') if review.nil?
      else
        info _('Notice: not retrieving album review (missing album or artist)')
      end

      output_tag('ALBUM_REVIEW', review, false)
    end

    ### Sends YEARS_ACTIVE => data if found
    def handle_years_active
      output_tag('STATUS', _('Retrieving years active..')) if @options.gui

      if @options.artist
	artist = Artist.new(@options.artist)

	begin
	  years = artist.years_active

	  unless years
	    regexp_list(@options.artist, @config['artist_cond_regex']) do |a|
	      years = Artist.new(a).years_active
	      break if years
	    end
	  end

	rescue DataAccessor::AccessorNotImplemented
	  years = nil
	end
      else
	info _('Notice: not retrieving years active (missing artist)')
	years = nil
      end

      output_tag('YEARS_ACTIVE', years, false)
    end

    ### Sends any song information that we have
    ### - title, artist, album
    def handle_song_info
      output_tag('TITLE', @options.title) if @options.title
      output_tag('ARTIST', @options.artist) if @options.artist
      output_tag('ALBUM', @options.album) if @options.album
    end

    ### Outputs the tag to $output
    ### [key] The key for the data
    ### [data] The data associated with the key
    ### [binary] Set to true if it is binary data, false is default
    def output_tag(key, data, binary=false)
      data = '' unless data

      element = REXML::Element.new(key.downcase)

      if binary
	element.attributes['encoded'] = 'base64' if binary
	element.text = Base64::encode64(data)
      else
	if data.include?("\n")
	  element.text = REXML::CData::new(data)
	else
	  element.text = data
	end
      end

      @output.puts "\t" + element.to_s
    end

    ### Output the XML file header
    def xml_header
      @output.puts "<?xml version='1.0'?>"
      @output.puts '<musicextras>'
    end

    ### Output the XML file footer
    def xml_footer
      @output.puts '</musicextras>'
    end

    ### Displays string on STDOUT if @options.verbose is set
    ### [+msg+] The message to display
    def info(msg)
      puts(msg) if @options.verbose
    end

  end
end

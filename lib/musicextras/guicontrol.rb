#!/usr/bin/ruby -w
#
# guicontrol - Controller for GUI
#
# version: $Id: guicontrol.rb 324 2004-05-21 13:15:11Z kapheine $
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
require 'optparse'
require 'ostruct'
require 'socket'
require 'rexml/document'
require 'rexml/streamlistener'
require 'base64'
require 'fileutils'

autoload :GtkGui, 'musicextras/gui/gtkgui'

module MusicExtras

  ### Provides interface to guis
  class GuiControl
    include REXML::StreamListener
    include Debuggable

    # GUI instance
    attr_reader :gui

    PROGNAME = File.basename($0)

    ### Creates the gui control
    ### [+guiclass+] The class of the Gui to load. Defaults to GtkGui
    def initialize(guiclass=GtkGui, args=ARGV)
      @gui = guiclass.new(self)
      @config = MConfig.instance

      Debuggable::setup()
      debug(1, "Running as: #{$PROGRAM_NAME} #{ARGV.join(' ')}")

      @hostname, @port = @config['gui_host'].split(':')
      @port ||= MConfig::DEFAULT_GUI_PORT

      @title = @artist = @album = nil
      @lyrics_file = nil

      # XXX: Shouldn't be using the global form
      Thread.abort_on_exception = true
      @clients = Array.new
      create_input_thread()

      parse_options(args)
    end

    ### Start up the Gui
    def start
      @gui.start
    end

    ### when the Close button is clicked...
    def close_clicked
      @gui.stop
    end

    ### Loads up an editor for the current lyrics file
    def edit_lyrics
      system(@config['editor'] % @lyrics_file) if @lyrics_file
    end

    ### Sets the current message on the statusbar
    ### [+msg+] The message to display
    def set_status(msg)
      @gui.set_status(msg)
    end

    ### Starts up a thread with a tcp server. The thread will wait for
    ### for incoming XML. When it receives some, it will pass
    ### the necessary method to update the gui information
    def create_input_thread # :nodoc:
      Thread.new do
        server = TCPServer.new(@hostname, @port)

	while (session = server.accept)
	  Thread.new do
            begin
              @clients << session

              check_clients()
              doc = REXML::Document.parse_stream(session, self)
	      @gui.done_parsing

              set_status('')
              @clients.delete(session)
            rescue IOError
              @clients.delete(session)
            end
	  end
	end

      end
    end

    def tag_start(item, attrs) # :nodoc:
      @current_tag = item
      @text = ''

      if attrs['encoded']
	@decode = true
      else
	@decode = false
      end
    end

    def text(item) # :nodoc:
      @text = item.to_s 
    end

    def cdata(data) # :nodoc:
      @text = data.to_s
    end

    def tag_end(item) # :nodoc:
      tag = @current_tag
      return unless tag
      data = @text

      if @decode == true
	data = Base64::decode64(data)
      end

      case tag
      when 'lyrics'
	@gui.set_lyrics(data)
      when 'lyrics_file'
	@lyrics_file = data
      when 'status'
	@gui.set_status(data)
      when 'artist_image'
	@gui.set_artist_image(data == '' ? nil : data)
      when 'album_cover'
	@gui.set_album_cover(data == '' ? nil : data)
      when 'title'
	@title = data
        @gui.set_song(@title, @artist)
      when 'artist'
	@artist = data
	if @title
	  @gui.set_song(@title, @artist)
	end
      when 'album'
        @album = data
        if @title
          @gui.set_song(@title, @artist, @album)
        end
      when 'biography'
	@gui.set_biography(data)
      when 'years_active'
	@gui.set_years_active(data)
      when 'album_review'
        @gui.set_review(data)
      when 'album_year'
	@gui.set_album_year(data) if data != ''
      when 'album_tracks'
	@gui.set_tracks(data)
      else
      end

      @current_tag = nil
    end

    private

    ### Checks for multiple clients. All except the latest are disconnected.
    ### (Well really, the socket is just closed, and the client is left to 
    ### figure out he has been disconnected)
    def check_clients
      unless @clients.size == 1
	@clients[0..-2].each do |c|
	  # close the stream on them. they should catch the error and
	  # assume we disconnected them. yeah it's dirty.
          debug(3, "Removing client")
	  c.close
	  @clients.delete(c)
	end
      end
    end

    ### Parse the options, returning a has of options
    def parse_options(args)
      @options = OpenStruct.new

      opts = OptionParser.new do |opts|
        opts.banner = version()
        opts.separator ""
        opts.separator "%s: musicextras-gui <options>" % "Usage"

        opts.on("-h", "--help", "displays this usage") do
          puts opts
          exit 0
        end
        opts.on("-V", "--version", "displays version information") do
          puts version()
          exit 0
        end

        opts.on("-d", "--debug-level=[LEVEL]", Integer, "sets debug level (defaults to 3)") do |o|
          @config['debug_level'] = o || 3
          file = File.join(@config['basedir'], "debug.log")
          @config['debug_io'] = File.open(file, "a")
          @config['debug_io'].sync = true
        end
      end

      begin
        opts.parse!(args)
      rescue OptionParser::InvalidOption => e
        $stderr.puts "%s: invalid option -- %s" % [PROGNAME, e.args[0]]
        exit 1
      end

      @options
    end

    ### Returns version information
    def version
      "#{PROGNAME} #{Version}\n" +
      "Copyright (C) 2004 Zachary P. Landau"
    end
  end

end

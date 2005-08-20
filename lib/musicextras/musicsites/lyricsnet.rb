#!/usr/bin/ruby -w
#
# lyricsnet - www.lyrics.net.ua implementation of MusicSite
#
# version: $Id: lyricsnet.rb 331 2004-07-07 22:48:11Z kapheine $
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

require 'musicextras/musicsite'
require 'musicextras/song'
require 'musicextras/debuggable'

module MusicExtras

  ### This is an implementation of MusicSite for www.lyrics.net.ua
  class LyricsNet < MusicSite
    attr_accessor :song # :nodoc:

    register()

    NAME = 'LyricsNet'
    URL = 'www.lyrics.net.ua'
    DESCRIPTION = 'Lyrics for multiple genres'

    def initialize
      super(NAME, URL)

      Song::register_plugin(self, :lyrics, CACHE_PATH['lyrics'])
    end

    # Fetches lyrics from the site, returning the lyrics as string
    # [+song+] a Song object
    #
    # Note: returns nil if something went wrong (including just not being able
    # to find the lyrics)
    def lyrics(new_song)
      @song = new_song

      unless @song.title and @song.artist
	debug(1, "song title or artist not specified")
	return nil
      end

      song_url = get_song_url()
      return nil unless song_url
      debug_var { :song_url }
      page = fetch_page(song_url, nil, MusicSite::USERAGENTS['Mozilla'])
      page.gsub!(/(<td.*?>)/, '\1<br/><br/>')
      text = extract_text(page, 
			  /<\/b><\/font><\/td><\/tr>\n(.*?)\n<\/p><\/td><\/tr><\/table><\/td><\/tr>\n/m)
      text =~ /\(No lyrics avaible\)/ ? nil : text + source()
    end

    # Fetches the url where the artists are listed.
    # Warning: Assumes get_lyrics has checked for a valid Song object
    #
    # [+title+] May specify title if you don't want to use the default of song.title
    def get_artist_list_url(title=nil) # :nodoc:
      char = @song.artist.name[0].chr.downcase
      if (char == '0' || (char.to_i >= 1 && char.to_i <= 9))
	char = '0'
      end
      return "/#{char}"
    end

    # Fetches the url that lists an artist's songs or returns nil if artist
    # is not found.
    def get_artist_url # :nodoc:
      artist = @song.artist.name
      artist_url = get_artist_list_url(artist)
      return nil if !artist_url
      debug_var { :artist_url }
      page = fetch_page(artist_url)
      page.scan(/<a href=\/group\/(\d+?)>(.*?)<\/a><br>/) do |url, name|
	return "/group/#{url}" if match?(artist, name)
      end

      debug(1, "could not find url for #{@song.artist.name}")
      return nil
    end

    # Fetches the url for an artist's song of returns nil if song is not found
    # Calls get_artist_url
    def get_song_url # :nodoc:
      artist_url = get_artist_url()
      return nil if !artist_url
      debug_var { :artist_url }
      page = fetch_page(artist_url)
      return nil if !page
      page.scan(/<a href=\/song\/(\d+)>(.*?)<\/a>/) do |url, name|
	return "/song/#{url}" if match?(@song.title, name, true)
      end

      debug(1, "could not get song url for #{@song.title} by #{@song.artist.name}")
      return nil
    end
  end
end

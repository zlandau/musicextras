#!/usr/bin/ruby -w
#
# lyricstime - www.lyricstime.com implementation of MusicSite
#
# version: $Id: lyricstime.rb 331 2004-07-07 22:48:11Z kapheine $
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
require 'musicextras/album'
require 'musicextras/song'
require 'musicextras/debuggable'

module MusicExtras

  # This is an implementation of MusicSite for www.lyricstime.com
  class LyricsTime < MusicSite
    attr_accessor :song, :album, :artist # :nodoc:

    register()

    NAME = 'LyricsTime'
    URL = 'www.lyricstime.com'
    DESCRIPTION = 'Lyrics and album covers for multiple genres'

    # Image used by the site when an album cover is unavailable
    NO_COVER_URL = '/images/l_no_cover.gif'

    def initialize
      super(NAME, URL)

      Song::register_plugin(self, :lyrics, CACHE_PATH['lyrics'])
      Album::register_plugin(self, :cover, CACHE_PATH['album_cover'])
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
      page = fetch_page(song_url)
      return extract_text(page, /<td class="lyrics">.*?\n(.*?)<br><br>\n/m) + source()
    end

    # Fetches album cover from the site, returning the image as binary
    # [+album+] an Album object
    #
    # Note: returns nil if something went wrong (including just not being able
    # to find the album cover)
    def cover(new_album)
      @album = new_album
      @song = Song.with_album('', @album)

      unless @album.title and @album.artist.name
	debug(1, "album title or artist name not specified")
	return nil
      end

      album_cover_url = get_album_cover_url()
      return nil unless album_cover_url
      debug_var { :album_cover_url }
      cover = fetch_page(album_cover_url)
      return cover
    end

    # Fetches the url where the artists are listed.
    # Warning: Assumes get_lyrics has checked for a valid Song object
    #
    # [+title+] May specify title if you don't want to use the default of song.title
    def get_artist_list_url(title=nil) # :nodoc:
      char = title ? title[0].chr.upcase : @song.artist.name[0].chr.upcase

      if (char == '0' || (char.to_i >= 1 && char.to_i <= 9))
	char = '0-9'
      end
      return "/#{char}/"
    end

    # Fetches the url that lists an artist's songs or returns nil if artist
    # is not found.
    def get_artist_url # :nodoc:

      artist = @song.artist.name

      artist_url = get_artist_list_url(artist)
      return nil if !artist_url
      debug_var { :artist_url }
      page = fetch_page(artist_url)
      unless page
	debug(1, "could not fetch page for #{song.artist.name}")
	return nil
      end
      page.scan(/<a href="\/artist\/([\w\s\-\|\(\)\:\+\?]+?)\/" title="(.*?) lyrics">(.*?)<\/a>/i) do |url, name|
	return "/artist/#{url}/" if match?(artist, name)
      end

      debug(1, "could not find url for #{artist}")
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
      page.scan(/<a title="(.*?) lyrics" href=\/lyrics\/(\d+).html>(.*?)<\/a><br>/i) do |name, url|
	return "/lyrics/#{url}.html" if match?(@song.title, name, true)
      end

      debug(1, "could not find url for #{@song.title} by #{@song.artist.name}")
      return nil
    end

    # Fetches the url for the album cover, returning nil if not found
    # Calls get_artist_url
    def get_album_cover_url # :nodoc:
      artist_url = get_artist_url()
      return nil if !artist_url
      page = fetch_page(artist_url)
      return nil if !page
      page.scan(/<img alt.*?album : (.*?)" title=.*? src="(.*?)" width=133 height=133>/) do |name, url|
	if match?(@song.album.title, name, true)
	  if url == NO_COVER_URL
	    break
	  else
	    return url
	  end
	end
      end

      debug(1, "could not find cover for #{@song.album.title} by #{@song.artist.name}")
      return nil
    end
  end

end

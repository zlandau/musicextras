#!/usr/bin/ruby -w
#
# lrcdb - www.lrcdb.org implementation of MusicSite
#
# version: $Id: $
#
# Copyright (C) 2003-2006 Zachary P. Landau <kapheine@hypa.net>
#                         Tony Cebzanov <tonyc@tonyc.org>
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
require 'cgi'

module MusicExtras

  ### This is an implementation of MusicSite for www.lrcdb.org
  class Lrcdb < MusicSite
    attr_accessor :song # :nodoc:

    register()

    NAME = 'lrcdb'
    URL = 'www.lrcdb.org'
    DESCRIPTION = 'Time-tagged song lyrics'

    def initialize
      super(NAME, URL)

      Song::register_plugin(self, :synced_lyrics, CACHE_PATH['synced_lyrics'])
    end

    # Fetches lyrics from the site, returning the lyrics as string
    # [+song+] a Song object
    #
    # Note: returns nil if something went wrong (including just not being able
    # to find the lyrics)
    def synced_lyrics(new_song)
      url_search = 'http://www.lrcdb.org/search.php'
      @song = new_song
      unless @song.title and @song.artist
	debug(1, "song title or artist not specified")
	return nil
      end
      post = "artist=#{CGI.escape(@song.artist.name)}&title=#{CGI.escape(@song.title)}&album=&query=plugin&type=plugin&submit=submit"
      page = fetch_page(url_search, post, MusicSite::USERAGENTS['Mozilla'])
      return nil unless page
      lid = nil
      page.scan(/^(?:exact|partial)+: (\d+)\s*(\S*)/mi) do |lid, alb|
        return nil unless lid
      end
      url_lyric = "http://www.lrcdb.org/lyric.php?lid=#{lid}&astext=yes"
      page = fetch_page(url_lyric, nil, MusicSite::USERAGENTS['Mozilla'])
      return nil if (lid == nil) 
      text=page
    end

    def test
      passed = true
      problems = []

      artist = Artist.new("Tori Amos")
      song = Song.new("Crucify", artist)

      if !synced_lyrics(song)
        passed = false
        problems << "synced_lyrics"
      end

      [passed, problems]
    end
  end

end

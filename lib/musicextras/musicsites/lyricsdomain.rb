#!/usr/bin/ruby -w
#
# lyricsdomain - www.lyricsdomain.com implementation of MusicSite
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
require 'musicextras/album'
require 'musicextras/song'
require 'musicextras/debuggable'

module MusicExtras

  # This is an implementation of MusicSite for www.lyricsdomain.com
  class LyricsDomain < MusicSite
    attr_accessor :song, :album, :artist # :nodoc:

    register()

    NAME = 'LyricsDomain'
    URL = 'www.lyricsdomain.com'
    DESCRIPTION = 'Lyrics for multiple genres'

    def initialize
      super(NAME, URL)
      Song::register_plugin(self, :lyrics, CACHE_PATH['lyrics'])
    end
    
    def urlify(txt)
      txt.gsub!(/[']/, "_") #'
      txt.gsub!(/ /, "_")
      txt.gsub!(%r![^\w\s-]+!, "")
      txt.gsub!(/_+/, "_")
      txt.downcase!()
      return txt
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
      artist = @song.artist.name
      letternum = artist[0].chr.upcase[0]
      title = @song.title
      a = urlify(artist)
      t = urlify(title)
      song_url = "http://www.lyricsdomain.com/#{letternum-64}/#{a}/#{t}.html"
      debug_var { :song_url }
      return nil unless song_url
      debug_var { :song_url }
      page = fetch_page(song_url)
      l = extract_text(page, %r!<pre>\s*\[.*?\] \[.*?\]\s*(.*?)</pre>!m)  #"
      return l
    end

    def test
      passed = true
      problems = []

      artist = Artist.new("Guns 'n Roses")
      album = Album.new("Appetite for Destruction", artist)
      song = Song.new("Sweet Child O'Mine", artist)

      if !lyrics(song)
        passed = false
        problems << "lyrics"
      end
      [passed, problems]
    end

  end
end

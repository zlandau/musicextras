#!/usr/bin/ruby -w
#
# song - Song Class
#
# version: $Id: song.rb 301 2004-04-09 22:43:54Z kapheine $
# usage: song
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

require 'musicextras/album'
require 'musicextras/artist'
require 'musicextras/dataaccessor'
require 'mp3info'

module MusicExtras

  ### Holds and retrieves song information
  class Song < DataAccessor
    attr_accessor :title, :artist, :album

    # Thrown when an mp3 does not have a tag or the tag is missing required data
    class InvalidTagException < StandardError; end

    public

    ### Create song with an artist
    ### [+title+] a String containing the song title
    ### [+artist+] a String or Artist class containing the artist
    def initialize(title, artist)
      super()
      @title = title
      if artist.is_a?(Artist)
	@artist = artist
      else
	@artist = Artist.new(artist)
      end
    end

    ### Create song with an album
    ### [+title+] a String containing the song title
    ### [+album+] an Album class containing the album
    def Song::with_album(title, album)
      song = Song.new(title, album.artist)
      song.album = album

      return song
    end

    ### Create song from an mp3 tag
    ### [+file+] a String pointing to the tagged mp3
    ### Throws Song::InvalidTagException if the mp3 doesn't have a tag
    def Song::from_mp3_tag(file)
      t = Mp3Info.open(file)

      artist = nil
      title = nil
      album = nil

      # id3v1 take priority, so read them last (to overwrite id3v2's)
      if Mp3Info.hastag2?(file)
        artist = t.tag2['artist'] if t.tag2['artist'] && t.tag2['artist'] != ''
        title = t.tag2['title'] if t.tag2['title'] && t.tag2['title'] != ''
        album = t.tag2['album'] if t.tag2['album'] && t.tag2['album'] != ''
      end
      if Mp3Info.hastag1?(file)
        artist = t.tag1['artist'] if t.tag1['artist'] && t.tag1['artist'] != ''
        title = t.tag1['title'] if t.tag1['title'] && t.tag1['title'] != ''
        album = t.tag1['album'] if t.tag1['album'] && t.tag1['album'] != ''
      end

      raise InvalidTagException.new('No id3 tag for title') unless title
      raise InvalidTagException.new('No id3 tag for artist') unless artist

      song = Song.new(title, artist)
      song.album = Album.new(album, artist) if album

      t.close

      return song
    end

    ### Replaces the following values:
    ### * {TITLE}
    ### * {ARTIST}
    ### * {ALBUM}
    def cache_values(str)
      nstr = str

      nstr = nstr.gsub(/\{TITLE\}/, @title)
      nstr = nstr.gsub(/\{ARTIST\}/, @artist.name)

      unless album.nil?
	nstr = nstr.gsub(/\{ALBUM\}/, @album.title)
      else
	nstr = nstr.gsub(/\{ALBUM\}/, '')
      end

      return nstr
    end

  end

end

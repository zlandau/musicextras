#!/usr/bin/ruby -w
#
# album - Album Class
#
# version: $Id: album.rb 283 2004-03-27 23:56:06Z kapheine $
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

require 'musicextras/artist'
require 'musicextras/dataaccessor'

module MusicExtras

  ### Holds and retrieves album information
  class Album < DataAccessor
    attr_accessor :title, :artist

    public

    ### Create an album with a title and artist
    ### [+title+] a String containing the album title
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

    ### Replaces the following values:
    ### * {ALBUM}
    ### * {ARTIST}
    def cache_values(str)
      nstr = str

      nstr = nstr.gsub(/\{ALBUM\}/, @title)
      nstr = nstr.gsub(/\{ARTIST\}/, @artist.name)

      return nstr
    end

  end

end

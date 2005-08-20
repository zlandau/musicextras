#!/usr/bin/ruby -w
#
# artist - Artist Class
#
# version: $Id: artist.rb 283 2004-03-27 23:56:06Z kapheine $
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

require 'musicextras/dataaccessor'

module MusicExtras

  ### Holds and retrieves artist information
  class Artist < DataAccessor
    attr_accessor :name

    ### Create artist
    ### [+title+] a String containing the artist's name
    def initialize(name)
      super()
      @name = name
    end

    ### Replaces the following values:
    ### * {ARTIST}
    def cache_values(str)
      return str.gsub(/\{ARTIST\}/, @name)
    end

  end

end

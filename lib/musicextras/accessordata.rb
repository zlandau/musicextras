#!/usr/bin/ruby -w
#
# accessordata - AccessorData holds information to be passed between a plugin
#                and the class it is extending
#
# version: $Id: accessordata.rb 283 2004-03-27 23:56:06Z kapheine $
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

module MusicExtras

  ### AccessorData holds information to be passed between a plugin and the
  ### class it is extending. When a plugin registers itself with a class, it
  ### sends an AccessorData instance to the class.
  class AccessorData

    # Instance of plugin that is registering itself. Usually you will want
    # to pass in 'self'
    attr_accessor :plugin

    # A Symbol of the method in @plugin that will actually fetch the data
    # Eg: :get_lyrics
    attr_accessor :accessor

    # The path used to load and save the cached data (see Cache)
    attr_accessor :cache_path

    # [+plugin+] Plugin instance for this accessor (usually 'self')
    # [+accessor+] The method that fetches the data (eg: :get_lyrics)
    # [+cache_path+] Path used to load and save cached data
    def initialize(plugin, accessor, cache_path)
      @plugin = plugin
      @accessor = accessor
      @cache_path = cache_path
    end

    # Runs the fetch method (@plugin) for this accessor, returning whatever
    # that method returns. 
    # [+caller+] Parameter to pass to fetch method. Should always be the class
    #          that called run
    def run(caller)
      return @plugin.send(@accessor, caller)
    end

  end

end

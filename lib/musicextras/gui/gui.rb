#!/usr/bin/ruby -w
#
# gui - Base GUI class
#
# version: $Id: gui.rb 256 2004-03-20 08:03:55Z kapheine $
#
# Copyright (C) 2004 Zachary P. Landau <kapheine@hypa.net>
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

module MusicExtras

  ### All Guis should inherit from this. This class implements all of the
  ### necessary methods for a Gui. If there are any datatypes you choose
  ### not to handle, just don't redefine them. The default behavior is to
  ### be quiet
  ###
  ### Once you implement your Gui, edit musicextras-gui and replace
  ### GuiControl.new.start with GuiControl(YourGuiClass).new.start
  class Gui

    # The GuiControl instance that called us
    attr_reader :control

    ### [+control+] the GuiControl for this gui
    def initialize(control)
      @control = control
      @config = MConfig.instance
    end

    ### Starts Gui
    def start
    end

    ### Stops Gui
    def stop
    end

    ### Sets the song information
    def set_song(title, artist=nil, album=nil)
    end

    ### Sets the lyrics
    def set_lyrics(lyrics)
    end

    ### Sets biography information
    def set_biography(bio)
    end

    ### Sets years active (as a string)
    def set_years_active(years)
    end

    ### Sets the album review
    def set_album_review(review)
    end

    ### Sets the album cover. Should be nil to indicate no cover (ie: remove
    ### old one)
    ### [+cover+] Binary String containing album cover. Should be nil to
    ### indicate no cover (ie: remove old one)
    def set_album_cover(cover)
    end

    ### Sets the artist image.
    ### [+image+] Binary String containing artist image. Should be nil to 
    ### indicate no image (ie: remove old one)
    def set_artist_image(image)
    end

    ### Sets the status of fetching (ie: Retrieving artist image)
    ### [+msg+] A String to dispaly
    def set_status(msg)
    end

  end

end

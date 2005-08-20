#!/usr/bin/ruby -w
#
# textgui - Text based GUI
#
# version: $Id$
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

require 'musicextras/gui/gui'
require 'thread'

module MusicExtras

  class TextGui < Gui

    attr_reader :control

    ### [control] the GuiControl for this gui
    def initialize(control)
      @control = control
    end

    ### Starts Gui
    def start
      puts "Starting gui..."
      a = Thread.new do
        loop {
          sleep(0.25)
        }
      end

      a.join
    end

    ### Stops Gui
    def stop
      puts "Stopping gui..."
    end

    ### Sets the song information
    def set_song(title, artist=nil, album=nil)
      puts "Setting song information to title: #{title} artist: #{artist}" +
	 " album: #{album}"
    end

    ### Sets the lyrics
    def set_lyrics(lyrics)
      if lyrics
        puts "Setting lyrics to #{lyrics[0..50].gsub("\n", ' ')}..."
      else
        puts "No lyrics"
      end
    end

    ### Sets biography information
    def set_biography(bio)
      if bio
        puts "Setting biography to #{bio[0..50].gsub("\n", ' ')}..."
      else
        puts "No biography"
      end
    end

    ### Sets years active (as a string)
    def set_years_active(years)
      puts "Setting years active to #{years}"
    end

    def set_review(review)
      if review
        puts "Setting review to #{review[0..50].gsub("\n", ' ')}..."
      else
        puts "No review"
      end
    end

    ### Sets the album cover. Should be nil to indicate no cover (ie: remove
    ### old one)
    ### [+cover+] Binary String containing album cover. Should be nil to
    ### indicate no cover (ie: remove old one)
    def set_album_cover(cover)
      if cover
        puts "Setting album cover with #{cover.length} 'bytes'"
      else
        puts "No cover image"
      end
    end

    ### Sets the artist image.
    ### [+image+] Binary String containing artist image. Should be nil to 
    ### indicate no image (ie: remove old one)
    def set_artist_image(image)
      if image
        puts "Setting artist image with #{image.length} 'bytes'"
      else
        puts "No artist image"
      end
    end

    ### Sets the status of fetching (ie: Retrieving artist image)
    ### [+msg+] A String to dispaly
    def set_status(msg)
      puts "Status: #{msg}"
    end

  end

end

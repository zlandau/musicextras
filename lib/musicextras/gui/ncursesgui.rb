#!/usr/bin/ruby
#
# ncursesgui - ncurses interface for musicextras
#
# version: $Id$
#
# Copyright (C) 2003-2004, 2004 Zachary P. Landau <kapheine@hypa.net>
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
# $Id$

require 'musicextras/config'
require 'musicextras/gui/gui'
require 'musicextras/utils'
require 'ncurses'

module MusicExtras

  class NCursesGui < Gui

    def initialize(control)
      super(control)

      @title = ""
    end

    def start

      a = Thread.new do

      done = false

      begin
	setup_curses()
	begin
	  case Ncurses.getch()
	  when 'q'[0], 'Q'[0]
	    stop()
	    done = true
	  end
	  draw()
	  Ncurses.refresh()
	end 
      rescue Exception => msg
	puts msg
	shutdown_curses()
      end
      end

      a.join
    end

    def stop
      shutdown_curses()
    end
    
    def set_song(title, artist=nil, album=nil)
      @title = "#{artist}: #{title}"
      File.open("blah", "w") { |w| w.write("gotcha") }
    end

    def draw
      @info_box = Box.new(0, 0, 0, 3)
      @lyrics_box = Box.new(0, 3, 120, 40)

      @info_box.puts(@title)
    end

    def setup_curses
      Ncurses.initscr
      #Ncurses.cbreak
      Ncurses.noecho
      Ncurses.nonl
      Ncurses.stdscr.nodelay(true)
#      Ncurses.stdscr.intrflush(false)
      Ncurses.stdscr.keypad(true)
      Ncurses.timeout(0)

      Ncurses.doupdate()
    end

    def shutdown_curses
      Ncurses.echo
      Ncurses.nocbreak
      Ncurses.nl
      Ncurses.endwin
    end

    class Box
      attr_accessor :title, :window

      def initialize(start_x, start_y, columns, lines, title=nil)
	@title = title

	@start_x = start_x
	@start_y = start_y

        File.open("test.log", "w") {|f|
          f.write(lines.to_s+"\n")
          f.write(columns.to_s+"\n")
          f.write(start_y.to_s+"\n")
          f.write(start_x.to_s+"\n")
        }
	@window = Ncurses::newwin lines, columns, start_y, start_x
        #@window.border(1, 2, 3, 4, 5, 6, 7, 8)
	#@window.border(*([0]*8))
	#@window.noutrefresh
      end

      def puts(str)
	@window.move(@start_y+1, @start_x+2)
	@window.addstr(str)
      end

    end

  end
end

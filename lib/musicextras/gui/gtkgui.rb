#!/usr/bin/ruby -w
#
# gtkgui - Gtk interface for musicextras
#
# version: $Id: gtkgui.rb 318 2004-04-29 02:37:37Z kapheine $
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

require 'musicextras/gui/gui'
require 'musicextras/utils'
require 'musicextras/pusher'
require 'libglade2'
require 'tmpdir'
require 'mp3info'

module MusicExtras

  ### Gtk Gui interface to musicextras
  ### See Gui documentation for more information
  class GtkGui < Gui

    def initialize(control)
      super(control)

      Gtk.init
      @glade = GladeXML.new(File.join(DATA_DIR, "musicextras.glade"), nil, "musicextras-gui") { |handler| method(handler) }
      @title = @artist = @album = nil
      init_main_window()
      init_change_song_dialog()
      init_extra_window()
      #init_searching()
    end

    def start
      Gtk.main
    end

    def stop
      Gtk.main_quit
      Gtk.main_iteration	    # to make quit effective? why is this needed?
    end

    ### For now this just sets the title and (if given) artist 
    def set_song(title, artist=nil, album=nil)
      g_title = title || ''
      g_artist = artist || ''
      g_album = album || ''

      @title = g_title
      @artist = g_artist
      @album = g_album

      str = title
      str = "#{artist}: " + str if artist
      str = str + " (#{album})" if album

      @glade.get_widget('album_frame').label = @album if album
      @glade.get_widget('artist_frame').label = @artist if artist

      @main_window.set_title(str)
    end

    def set_lyrics(lyrics)
      @lyrics_text.buffer.set_text(lyrics)
    end

    def set_tracks(tracks)
      @tracks = tracks
    end

    def set_biography(bio)
      @bio_text.buffer.set_text(bio)
    end

    def set_review(review)
      @review_text.buffer.set_text(review)
    end

    def set_years_active(years)
    end

    def set_album_cover(cover)
      @album_image.pixbuf = process_image(cover)
    end

    def set_album_year(year)
      @glade.get_widget('album_frame').label += " (#{year})" 
    end

    def set_artist_image(image)
      @artist_image.pixbuf = process_image(image)
    end

    def process_image(data)
      if data.nil?
	ret = Gdk::Pixbuf.new(@no_image_available)
      else
	begin
	  loader = Gdk::PixbufLoader.new
	  loader.write(data)

	  pixbuf = loader.pixbuf
          if pixbuf.height > pixbuf.width
            scale_h = @image_size
            scale_w = ( ( pixbuf.width.to_f / pixbuf.height.to_f ) * @image_size).round
          else
            scale_h = ( ( pixbuf.height.to_f / pixbuf.width.to_f ) * @image_size).round
            scale_w = @image_size
          end
	  pixbuf = pixbuf.scale(scale_w, scale_h)
	  ret = pixbuf

	  loader.close
	rescue RuntimeError
	  # probably couldnt recognize the file type, call ourselves with nil
	  process_image(nil)
	end
      end

      ret
    end

    def set_status(msg)
      @statusbar.pop(1)
      @statusbar.push(1, msg)
    end

    def done_parsing
      #if @title == '' && defined? @tracks
      #	@lyrics_text.buffer.set_text(@tracks)
      #end
    end

    private

    def init_main_window
      @main_window = @glade.get_widget('main_window')
      @main_window.resize(@config['window_w'], @config['window_h'])
      @main_window.show

      @lyrics_text = @glade.get_widget('lyrics_text')
      @album_image = @glade.get_widget('album_image')
      @artist_image = @glade.get_widget('artist_image')
      @statusbar = @glade.get_widget('statusbar')

      @image_size = @config['image_size'] || 200
      @no_image_available = File.join(DATA_DIR, 'no_image.png')

      set_album_cover(nil)
      set_artist_image(nil)

      @right_click_menu = @glade.get_widget('right_click_menu')
    end

    def init_extra_window
      @extra_window = @glade.get_widget('extra_window')
      @extra_window.resize(@config['window_w'], @config['window_h'])

      @bio_text = @glade.get_widget('bio_text')
      @review_text = @glade.get_widget('review_text')
      @years_active_text = @glade.get_widget('years_active_text')
    end

    def init_change_song_dialog
      @change_song_dialog = @glade.get_widget('change_song_dialog')
      @artist_label = @glade.get_widget('artist_label')
      @title_label = @glade.get_widget('title_label')
      @album_label = @glade.get_widget('album_label')
    end

    def init_searching
      # Set some stuff up for the incremental searching
      buffer = @lyrics_text.buffer
      @search_buffer = nil
      buffer.place_cursor(buffer.start_iter)
      @search_end_iter = buffer.start_iter
    end

    def error(msg)
      mdialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL,
	Gtk::MessageDialog::Type::ERROR, Gtk::MessageDialog::ButtonsType::OK, msg)
      ret = mdialog.run
      mdialog.hide
    end

    ### When close button is clicked...
    def on_close_button_clicked
      @control.close_clicked
    end

    ### When extra info close button is clicked..
    def on_extra_close_clicked
      @extra_window.hide
    end

    def on_lyrics_click(w, event)
      if event.button == 3
	@right_click_menu.popup(nil, nil, event.button, event.time)
      end
    end

    def on_edit_activate
      @control.edit_lyrics
    end

    def on_more_information_activate
      @extra_window.show
    end

    def on_change_song_activate
      @artist_label.text = @artist || ''
      @album_label.text = @album || ''
      @title_label.text = @title || ''

      @change_song_dialog.show
    end

    def on_change_song_cancel_clicked
      @change_song_dialog.hide
    end

    def on_change_song_open_clicked
      dialog = @glade.get_widget('filechooserdialog')
    
      begin
	ret = dialog.run

	if ret == Gtk::Dialog::RESPONSE_OK
	  Mp3Info.open(dialog.filename) do |m|
	    @artist_label.text = m.tag['artist']
	    @title_label.text = m.tag['title']
	    @album_label.text = m.tag['album']
	  end
	elsif ret == Gtk::Dialog::RESPONSE_CANCEL
	end
      rescue Mp3InfoError
	error("Error reading mp3 tag")
	retry
      rescue => e
	error(e.message)
      end

      dialog.hide
    end

    def on_change_song_ok_clicked
      @change_song_dialog.hide
      artist = @artist_label.text
      title = @title_label.text
      album = @album_label.text

      opts = []
      opts << "-a" << artist unless artist == ''
      opts << "-t" << title unless title == ''
      opts << "-l" << album unless album == ''

      return if opts.length == 0

      Thread.new do
        system("musicextras", *opts)
      end

      @artist_label.text = ""
      @title_label.text = ""
      @album_label.text = ""
    end

    ### Called when a key is pressed anywhere in window
    ### [window] the GtkWindow the key was pressed in
    ### [event} the GdkEvent created
    def on_key_press(window, event)
      # Warning: don't look at this code. in case of accidentally viewing,
      # induce vomiting. just kidding, you will vomit anyway.


      buffer = @lyrics_text.buffer

      if event.keyval == 65307 # ESC
	@search_buffer = nil
	buffer.place_cursor(buffer.start_iter)
	@statusbar.pop(1)

      elsif event.keyval == 47 # /
	if @search_buffer.nil?
	  @search_buffer = ""

	  # Put cursor back at beginning of text
	  buffer.place_cursor(buffer.start_iter)
	  @search_end_iter = buffer.start_iter

	  @statusbar.push(1, "Incremental search, start typing")
	end

      elsif event.keyval == 103 and ((event.state & Gdk::Window::CONTROL_MASK) != 0) # g

	if @search_buffer
	  buffer.place_cursor(@search_end_iter) if @search_end_iter
	  @search_end_iter = search_text(@search_buffer)
	end

      elsif event.keyval.between?(1, 255) # Any other chars
	unless @search_buffer.nil?
	  if (@search_end_iter = search_text(@search_buffer+event.keyval.chr))
	    @search_buffer += event.keyval.chr
	    @statusbar.pop(1)
	    @statusbar.push(1, "Search: #{@search_buffer}") if @search_end_iter
	  end
	end

      end
    end

    ### Searches for given text in lyrics box. Highlights the text if found.
    ### Returns a GtkTextIter pointing to the end of the search term, or nil
    ### if nothing is found.
    ### [txt] a String to search for
    ### [wrap] Will wrap search if true. Defaults to true.
    def search_text(txt, wrap=true)
      end_iter = nil
      buffer = @lyrics_text.buffer
      iter = buffer.get_iter_at_mark(buffer.get_mark('insert'))

      if !found and wrap
	buffer.place_cursor(buffer.start_iter)
	found = iter.forward_search(txt, 0, nil)
      end

      if found
	buffer.place_cursor(found[0])
	buffer.move_mark('selection_bound', found[-1])
	end_iter = found[-1]
      end

      end_iter

=begin 
      ### XXX: not working yet
      
      if found
	@prev_search_iters = found
	#return @prev_search_iters[-1]
	return found[-1]
      elsif @prev_search_iters
	#buffer.place_cursor(@prev_search_iters[0])
	#buffer.move_mark('selection_bound', @prev_search_iters[-1])
	return @prev_search_iters[-1]
      end

      end_iter
=end

    end

    ### Writes a string containing an image to a temporary file, returns the
    ### full filename
    ### [image] a Binary String containing the image
    ### [filename] filename to use in Dir.tmpdir
    def write_image_to_file(image, filename)
      file = File.join(Dir.tmpdir, filename)

      File.open(file, 'w') do |f|
	f.write(image)
      end

      return file
    end
  end

end

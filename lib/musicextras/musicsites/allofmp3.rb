#!/usr/bin/ruby -w
#
# Allofmp3 - www.allofmp3.com implementation of MusicSite
#
# Copyright (C) 2003-2006 Paul-henri Ferme <paul-henri.ferme@noos.fr>
#                         Zachary P. Landau <kapheine@hypa.net>
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
require 'musicextras/artist'
require 'musicextras/debuggable'
require 'cgi'

module MusicExtras

  ### This is an implementation of MusicSite for www.allifmp3.com
  class Allofmp3 < MusicSite
    attr_accessor :artist, :album # :nodoc:

    register()

    NAME = 'Allofmp3'
    URL = 'www.allofmp3.com'
    DESCRIPTION = 'Artist images, album covers for many genres'

    def initialize
      super(NAME, URL)

      Artist::register_plugin(self, :image, CACHE_PATH['artist_image'])
      Album::register_plugin(self, :cover, CACHE_PATH['album_cover'])
    end

    # Fetches artist image from site, returning the image as a binary string
    # [+artist+] an Artist object
    #
    # Note: returns nil if something went wrong (including not being able to
    # find the artist image)
    def image(new_artist)
      @artist = new_artist

      unless @artist.name
	debug(1, "artist not specified")
	return nil
      end

      page = get_artist_page
      return nil unless page
      page.scan(%r!<div class="albumcover">\s*<img src="([^"]+?)"!) do |image_url|
	debug_var { :image_url }
	return fetch_page(image_url.to_s)
      end 

      nil
    end

    # Fetches album cover from the site, returning the image as a binary string
    # [+album+] an Album Object
    #
    # Note: returns nil if something went wrong
    def cover(new_album)
      @album = new_album
      @artist = new_album.artist

      unless @album.title and @album.artist.name
	debug(1, "album title or artist not specified")
	return nil
      end

      album_cover_url = get_album_cover_url
      debug_var { :album_cover_url }
      return nil unless album_cover_url
      return fetch_page(album_cover_url)
    end

    # Returns the page allofmp3 returns in a search for the artist.
    # Returns nil if something went wrong (including just not finding the page)
    def get_artist_page # :nodoc:
      post = "result=ON&search=#{CGI::escape(@artist.name)}&ybeg=0&yend=0&sg=1&sa=1&ss=1"
      debug_var { :post }
      body = fetch_page("http://search.allofmp3.com/search.shtml", post)

      unless body
	debug(1, "could not fetch page for @{artist.name}")
	return nil
      end

      if body !~ /.*No entries found for.*/
        body.scan(%r!<a href="(http://music.allofmp3.com/mp3/[^"]+)">((?:</?strong>|</?em>|[^>])+)</a>!) do |url, name|
          name.gsub!(%r!</?[^>]+>!, "")
          debug_var { :url }
          debug_var { :name }
	  if match?(@artist.name, name)
	    return fetch_page(url.to_s)
	  else
	    debug(1, "artist page for #{@artist.name} not found")
	    return nil
	  end
	end

	# if the regexp failed, give up
        debug(1, "artist page for #{@artist.name} not found")
	return nil
      else
	return nil
      end

    end

    # Returns an array:  [album, album_url]
    # or nil if none were found
    def get_album_urls
      albums = []

      page = get_artist_page()

      albref = nil

	if page
      page.scan(/var albref\s+= '(\d+)'/m) do |albref|
        page_albref = albref.to_s
      end
      page.scan(%r!<a href="(http://music.allofmp3.com/[^']+?mcatalog\.shtml)'.*?;</script>\s*<strong>([^<]+)</strong></a>!) do |url, name|
                url = "#{url}?albref=#{albref}"
	    debug(5, "#{name} => #{url}")
	    albums<< [name, url]
	  end
	else
	  debug(2, "could not fetch discography for #{@artist.name}")
	end
      if albums.empty?
	return nil
      else
	return albums
      end
    end

    # Fetches the url for an album or returns nil if its not found
    # Calls get_artist_page
    def get_album_url # :nodoc:
      albums = get_album_urls()
      unless albums
	debug(1, "could not find any album urls for #{@artist.name}")
	return nil
      end
      albums.each do |album|
	return album[1].sub("songs3", "songs") if match?(@album.title, album[0], true)
      end

      debug(1, "album url for #{@album.title} by #{@artist.name} not found")
      return nil
    end

    # Fetches the album cover url. Calls get_album_url
    def get_album_cover_url # :nodoc:
      album_url = get_album_url()
      debug_var { :album_url }
      return nil if !album_url
      page = fetch_page(album_url)
      return nil if !page

      page.scan(%r!<div class="cover">\s*<img src="([^"]+?)"!) do |image_url|
	debug_var { :image_url }
	return image_url.to_s
      end 

      debug(1, "could not find cover for #{@album.title} by #{@album.artist.name}")
      return nil
    end

    def test
      passed = true
      problems = []

      artist = Artist.new("The Beatles")
      album = Album.new("Please Please Me", artist)

      if !image(artist)
	passed = false
	problems << "artist image"
      end
      if !cover(album)
	passed = false
	problems << "album cover"
      end

      [passed, problems]
    end

  end
end


#!/usr/bin/ruby -w
#
# allmusic - www.allmusic.com implementation of MusicSite
#
# version: $Id: allmusic.rb 331 2004-07-07 22:48:11Z kapheine $
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

require 'musicextras/musicsite'
require 'musicextras/album'
require 'musicextras/artist'
require 'musicextras/debuggable'
require 'cgi'

module MusicExtras

  ### This is an implementation of MusicSite for www.allmusic.com
  class AllMusic < MusicSite
    attr_accessor :artist, :album # :nodoc:

    register()

    NAME = 'AllMusic'
    URL = 'www.allmusic.com'
    DESCRIPTION = 'Artist images, album covers, years active, biography and album reviews for many genres'

    ACCESS_VIOLATION_MSG = "Through traffic and monitoring of our websites" # see check_for_violation
    COMMON_REGEX = '<a href="\/cg\/amg.dll\?p=amg&sql=([^"]*)">([^<]*)<\/a>'

    def initialize
      super(NAME, URL)

      Artist::register_plugin(self, :biography, CACHE_PATH['biography'])
      Artist::register_plugin(self, :image, CACHE_PATH['artist_image'])
      Artist::register_plugin(self, :years_active, CACHE_PATH['years_active'])
      Album::register_plugin(self, :cover, CACHE_PATH['album_cover'])
      Album::register_plugin(self, :review, CACHE_PATH['album_review'])
      Album::register_plugin(self, :tracks, CACHE_PATH['album_tracks'])
      Album::register_plugin(self, :year, CACHE_PATH['album_year'])
    end

    # Fetches artist image from site, returning the image as a binary string
    # [+artist+] an Artist object
    #
    # Note: returns nil if somethign went wrong (including not being able to
    # find the artist image)
    def image(new_artist)
      @artist = new_artist

      unless @artist.name
	debug(1, "artist not specified")
	return nil
      end

      page = get_artist_page
      return nil unless page
      check_for_violation(page)
      page.scan(/<td valign="top">.*?<img src="http:\/\/image.allmusic.com\/([^"]*)"/) do |image_url|
	debug_var { :image_url }
	return fetch_page("http://image.allmusic.com/#{image_url}", nil, MusicSite::USERAGENTS['Mozilla'])
      end 

      debug(1, "Could not find image url for #{artist.name}")

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
      page = fetch_page("http://image.allmusic.com/#{album_cover_url}", nil, MusicSite::USERAGENTS['Mozilla'])
      unless page
	debug(1, "Could not fetch cover for #{@album.title} by #{@album.artist.name}")
	return nil
      end
      page
    end

    # Fetches artist biography info, returning nil if none is found
    # [+artist+] an Artist object
    # Calls get_artist_page
    def biography(new_artist)
      debug_enter(new_artist)

      @artist = new_artist

      page = get_artist_page()
      return nil if !page
      check_for_violation(page)

      ma = page.match(/<a HREF="([^"]*)">Biography<\/a>/i)

      if ma
	bio_page = fetch_page(ma[1], nil, MusicSite::USERAGENTS['Mozilla'])
      else
	debug(1, "could not find bio page for #{@artist.name}")
	return nil
      end

      ma = bio_page.match(/class="title">Biography<\/td><td align="[^"]*" class="author">by\s*?([^<]*)<\/td>.*?<p>(.*?)<!--End Center Content/mi)

      if ma
        extract_text(ma[2], /(.*)/mi) + "\nSource: #{ma[1]} from #{self.to_s}\n"
      else
        debug(1, "could not fetch biography text for #{@artist.name}")
	nil
      end
    end

    # Fetches album review, returning nil if none is found
    # [+album+] an Album object
    def review(new_album)
      @album = new_album
      @artist = new_album.artist

      unless @album.title and @album.artist.name
        debug(1, "album title or artist not specified")
        return nil
      end

      album_url = get_album_url()
      return nil unless album_url
      debug_var { :album_url }

      page = fetch_page(album_url, nil, MusicSite::USERAGENTS['Mozilla'])
      check_for_violation(page)
      ma = page.match(/<a HREF="([^"]*)">Review<\/a>/i)
      if ma
	url = ma[1]
	debug_var { :url }
	review_page = fetch_page(url, nil, MusicSite::USERAGENTS['Mozilla'])
      else
	debug(1, "could not find review page for #{@album.title} by #{@album.artist.name}")
	return nil
      end

      ma = review_page.match(/class=\"title\">Review<\/td><td align="right" class="author">by\s*?([^<]*)<\/td>.*?<p>(.*?)<\/p><\/td><\/tr><\/table>/mi)

      if ma
        extract_text(ma[2], /(.*)/mi) + "\nSource: #{ma[1]} from #{self.to_s}\n"
      else
	debug(1, "could not find album review for #{@album.title} by #{@album.artist.name}")
        nil
      end
    end

    # Fetches the years the artist was active for, returning nil if not found
    # [+artist+] an Artist object
    def years_active(new_artist)
      debug_enter()

      @artist = new_artist

      page = get_artist_page()
      return nil if !page

      active = nil

      page.scan(/<div class="timeline-sub-active">(\d?\d?\d\d)/) do |d|
	if active
	  active += " #{d}s"
	else
	  active = "#{d}s"
	end
      end

      return active
    end

    # Returns the page allmusic returns in a search for the artist.
    # Returns nil if something went wrong (including just not finding the page)
    def get_artist_page # :nodoc:
      post = "sql=#{CGI::escape(@artist.name)}&P=amg&opt1=1"
      
      debug_var { :post }
      body = fetch_page("/cg/amg.dll", post, MusicSite::USERAGENTS['Mozilla'])

      if body =~ /.*Name Search Results for.*/
	body.scan(/#{COMMON_REGEX}/mi) do |url, name|
	  debug_var { :url }
	  if match?(@artist.name, name)
	    return fetch_page("/cg/amg.dll?P=amg&sql=#{url}", nil, MusicSite::USERAGENTS['Mozilla'])
	  else
	    debug(1, "artist page for #{@artist.name} not found")
	    return nil
	  end
	end

	# if the regexp failed, give up
        debug(1, "artist page for #{@artist.name} not found")
	return nil
      else
	return body
      end

    end

    # Returns an array:  [album, album_url]
    # or nil if none were found
    def get_album_urls
      page_types = ['Main Albums', 'Compilations', 'Singles & EPs']
      album_pages = []
      albums = []

      page = get_artist_page()
      return nil if !page
      ma = page.match(/<a HREF="([^"]*)">Discography<\/a>/i)
      unless ma
	debug(1, "discography page for #{@artist.name} not found")
	return nil
      end

      disco_url = ma[1]
      disco_page = fetch_page(disco_url, nil, MusicSite::USERAGENTS['Mozilla'])
      unless disco_page
	debug(1, "could not fetch discography page for #{@artist.name}")
	return nil
      end

      page_types.each do |page_type|
	ma = disco_page.match(/<a HREF="([^"]*)" class="[^"]*">#{page_type}<\/a>/)
	if ma
	  album_pages << ma[1]
	  debug(5, "adding #{ma[1]} to album url list")
	else
	  debug(2, "could not find #{page_type} discography url for #{@artist.name}")
	end
      end

      album_pages.each do |url|
	page = fetch_page(url, nil, MusicSite::USERAGENTS['Mozilla'])
	if page
	  page.scan(/#{COMMON_REGEX}/mi) do |url, name|
	    debug(5, "#{name} => #{url}")
	    albums<< [name, url]
	  end
	else
	  debug(2, "could not fetch #{page_type} discography for #{@artist.name}")
	end
      end

      if albums.empty?
	debug(2, "list of albums is empty for #{@artist.name}")
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
	return "/cg/amg.dll?P=amg&sql=#{album[1]}" if match?(@album.title, album[0], true)
      end

      debug(1, "album url for #{@album.title} by #{@artist.name} not found")
      return nil
    end

    # Fetches the track listing for a page
    def tracks(new_album)
      @album = new_album
      @artist = new_album.artist

      album_url = get_album_url()
      debug_var { :album_url }
      return nil if !album_url
      page = fetch_page(album_url, nil, MusicSite::USERAGENTS['Mozilla'])
      if !page
	debug(1, "could not fetch tracks page for #{@artist.name}")
	return nil
      end
      check_for_violation(page)

      tracks = "\n"
      found = false
      page.scan(/<TD class="cell">(\d*?)<\/TD>.*?<a href="\/cg\/amg.dll\?p=amg&sql=[^"]*">([^<]*)<\/a>/mi) do |num, name|
	found = true
	tracks += sprintf("%3i. %s\n", num, name)
      end

      if found
	return tracks
      else
	debug(1, "No tracks found for #{@album.title} by #{@artist.name}")
	return nil
      end
    end
 
    def year(new_album)
      @album = new_album
      @artist = new_album.artist

      album_url = get_album_url()
      debug_var { :album_url }
      return nil if !album_url
      page = fetch_page(album_url, nil, MusicSite::USERAGENTS['Mozilla'])
      if !page
	debug(1, "could not fetch album page for #{@artist.name}")
	return nil
      end
      check_for_violation(page)

      ma = page.match(/<span>Release Date.*?sub-text.*?(\d{4,4})</)

      if ma
	return ma[1]
      else
	debug(1, "No release year found for #{@album.title} by #{@artist.name}")
	return nil
      end
    end

    # Fetches the album cover url. Calls get_album_url
    def get_album_cover_url # :nodoc:
      album_url = get_album_url()
      debug_var { :album_url }
      return nil if !album_url
      page = fetch_page(album_url, nil, MusicSite::USERAGENTS['Mozilla'])
      return nil if !page
      check_for_violation(page)

      page.scan(/<td valign="top">.*?<img src="http:\/\/image.allmusic.com([^"]*)"/) do |image_url|
	debug_var { :image_url }
	return image_url[0]
      end 

      debug(1, "could not find cover for #{@album.title} by #{@album.artist.name}")
      return nil
    end

    # AllMusic.com seems to check for an abnormal number of accesses from IPs.
    # This method should be called after initial fetches to see if the user is
    # in violation.  If so, it will print the message to stdout and exit with
    # error code 100
    def check_for_violation(html)
      if html =~ /#{ACCESS_VIOLATION_MSG}/
	$stderr.puts html.strip_html
	$stderr.puts "AllMusic.com IP Violation, temporarily remove AllMusic.com from your plugin list"
	exit 100
      end
    end
 
    def test
      passed = true
      problems = []

      artist = Artist.new("Bob Dylan")
      album = Album.new("Blood on the Tracks", artist)

      if !image(artist)
	passed = false
	problems << "artist image"
      end
      if !cover(album)
	passed = false
	problems << "album cover"
      end
      if !biography(artist)
	passed = false
	problems << "biography"
      end
      if !review(album)
	passed = false
	problems << "review"
      end
      if !years_active(artist)
	passed = false
	problems << "years active"
      end
      if !tracks(album)
	passed = false
	problems << "tracks"
      end
      if !year(album)
	passed = false
	problems << "album year"
      end

      [passed, problems]
    end

  end
end

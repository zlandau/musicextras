#!/usr/bin/ruby -w
#
# utils - extra stuff
#
# version: $Id: utils.rb 326 2004-07-05 12:53:16Z kapheine $
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

require 'iconv'
begin
  require 'gettext'
rescue LoadError
end

class String
  # Specifies the cutoff point for mangle()
  # This should be, at the maximum, no more than the length of an mp3
  # tag, since we will often be getting our information from them.
  # Shortening it further may produce better results in some cases, but
  # it is probably okay how it is
  MANGLE_CUTOFF_POINT = 22

  # Removes everything except word characters and shortens string to
  # MANGLE_CUTOFF_POINT. This is used to match song titles when spaces,
  # punctuation etc may be different.
  #
  # [+remove_pronouns+] Set to true if prefixing pronouns should be removed.
  # Defaults to false.
  def mangle(remove_pronouns=false)
    s = self.dup

    if remove_pronouns
      s = s.gsub(/^The /i, '').
	    gsub(/^Los /i, '').
	    gsub(/^Las /i, '').
	    gsub(/^El /i, '').
	    gsub(/^La /i, '')
    end

    s.downcase.				# ignore case
      gsub(/&/, 'and').			# change &s to 'and's
      gsub(/\([^\)\Z]*(?:\)|\Z)/, '').  # remove text within ()s
      gsub(/\[[^\]\Z]*(?:\]|\Z)/, '').  # remove text within []s
      gsub(/:.*/, '').			# remove anything after a :
      gsub(/[\W_]/u, '').		# remove all non-word chars
      to_s[0, MANGLE_CUTOFF_POINT]	# shorten the string
  end

  # Converts a string of html to text
  # * Turns ^Ms and <br>s into newlines
  # * Replaces html entities with their expected value
  # * Removes html tags
  def strip_html
    str = self.dup

    str.gsub!(/\r/, "")          # XXX: replace this with an escape sequence
    str.gsub!(/<p>/i, "\n")
    str.gsub!(/<br(.*?)>/i, "\n")
    str.gsub!(/&gt;/, '>')
    str.gsub!(/&lt;/, '<')
    str.gsub!(/&amp;/, '&')
    str.gsub!(/&quot;/, '"')
    str.gsub!(/<.*?>/, '')

    return str.remove_extra_blanks
  end

  # Removes extra blank lines that may have shown up from HTML conversions.
  # Returns the new text
  # [+text+] the text to convert
  # XXX: May not always do what we want. Report any weirdness
  def remove_extra_blanks
    ret = self.dup

    # Remove extra newlines at beginning and end
    ret.gsub!(/\A[\n\s]+/, '')
    ret.gsub!(/[\n\s]+\n\Z/, "\n")

    # Remove doubled newlines
    if ret.match(/\n\n\n/)
      ret.gsub!(/\n\n/, "\n")
      ret.gsub!(/\n\n\n/, "\n\n")
    elsif ret.match(/\n\n/)
      ret.gsub!(/\n\n/, "\n")
    end

    ret
  end

  ### Converts text from +encoding+ to utf8. +encoding+ is read from readline's
  ### Locale.codeset if available. Otherwise it defaults to iso-8859-1. If +encoding+
  ### is defined, it overrules readline's Locale.codeset
  def to_utf8(encoding=nil)
    @@codeset = (defined? Locale) ? Locale.codeset : nil unless defined? @@codeset
    from = encoding || @@codeset || 'iso-8859-1'

    # hashish, but ANSI_ sucks as a locale
    if from.match(/^ANSI_/)
      from = 'iso-8859-1'
    end

    Iconv.conv("utf-8", from, self)
  end
end

class File

  ### Returns the first copy of 'filename' found in 'path'
  def File.find_in_path( filename, path )
    path.find do |dir| 
      try_file = File.join(dir, filename)
      return try_file if File.readable?(try_file)
    end
  end
end

unless defined? Base64
  module Base64
    public
    def self.decode64(str)
      str.unpack("m")[0]
    end

    def self.encode64(bin)
      [bin].pack("m")
    end
  end
end

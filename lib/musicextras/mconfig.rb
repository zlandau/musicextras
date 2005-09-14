#!/usr/bin/ruby -w
#
# mconfig - Configuration file handler
#
# version: $Id: config.rb 320 2004-04-30 23:17:38Z kapheine $
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

require 'singleton'
require 'musicextras/debuggable'

module MusicExtras
  Version = ''
  DATA_DIR = File.join(ENV['RUBYDATA'], 'musicextras')

  DAY = 86400
  WEEK = DAY*7
  MONTH = WEEK*4	# approximately

  ### Handles config file loading and access
  class MConfig
    include Singleton

    VALID = %w(basedir log verbose fetchers plugins use_cache gui_host 
               artist_pre_regex artist_cond_regex album_pre_regex window_w
               window_h image_size editor debug_level debug_io timeout
	       greylist_timeout updateurl)

    DEFAULT_GUI_PORT = 1665

    def initialize
      @values = {}
      @configs_loaded = false
    end

    def load_configs
      @configs_loaded = true

      begin
        require 'musicextras/musicextrasrc'

        begin
          require File.join(self['basedir'], 'musicextrasrc')
        rescue LoadError
          # ignore
        end
      rescue InvalidKey => e
        $stderr.puts e
        exit 1
      end
    end

    def []=(key, value)
      load_configs unless @configs_loaded

      if VALID.include? key
        @values[key] = value
      else
        raise InvalidKey.new(key)
      end
    end

    def [](key)
      load_configs unless @configs_loaded

      if VALID.include? key
        @values[key]
      else
        raise InvalidKey.new(key)
      end
    end

    class InvalidKey < StandardError
      def initialize(key)
        @key = key
        @error_file = caller[2]
      end

      def to_s
        "Invalid config term: #{@key} in #{@error_file}"
      end
    end
  end

end

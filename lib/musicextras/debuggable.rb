#!/usr/bin/ruby -w
#
# debuggable - provides debugging methods
#
# Copyright (C) 2004 Zachary P. Landau <kapheine@hypa.net>
# All rights reserved.
#

require 'musicextras/mconfig'
require 'fileutils'
require 'thread'

module MusicExtras

  ### Routines to assist with debugging
  module Debuggable
    DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    def self::setup
      @config = MConfig.instance unless defined? @config
      @config['debug_level'] ||= 1
      FileUtils.mkdir_p @config['basedir']
      file = File.join(@config['basedir'], "debug.log")
      @config['debug_io'] = File.open(file, "a")
      @config['debug_io'].sync = true
      @config['debug_io'].puts ""
    end

    def debug(level, msg, caller_depth=1)
      @config = MConfig.instance unless defined? @config
      $debug_mutex = Mutex.new unless defined? $debug_mutex

      meth = caller(caller_depth)[0].match(/\`(.*?)\'/)[1]
      debug_level = @config['debug_level'] || 0
      debug_io = @config['debug_io'] || STDERR
      FileUtils.mkdir_p(@config['basedir'])

      if (debug_level >= level)
        $debug_mutex.synchronize do
          debug_io.puts "[%s] debug[%s:%s]: %s" % [
            Time.now.strftime(DATETIME_FORMAT),
              self.class.to_s.split(/::/)[-1],
              meth, msg
          ]
        end
      end
    end

    def debug_enter(*params)
      str = params.empty? ? "" : "(params: #{params.join(' ')})"
      debug(1, "entering #{str}", 2)
    end

    def debug_leave
      debug(1, "leaving", 2)
    end

    def debug_var(&block)
      var = block.call
      debug(3, "#{var} = " + eval(var.to_s, block.binding).inspect, 2)
    end

    def debug_dump(filename, data)
      File.open(filename, "w") { |f| f.write(data) }
    end
  end
end

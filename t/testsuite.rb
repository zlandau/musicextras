#!/usr/bin/ruby -w
# :nodoc all
#
# Test Suite for Musicextras

$:.unshift( File.join( '..', 'lib' ))
require 'test/unit'

require 'musicextras/mconfig'
MusicExtras::MConfig.instance['basedir'] = "test_dir"

Dir['TC_*.rb'].each do |test|
  require test
end

puts 'NOTICE: run musicsites/testsuite.rb to test site plugins'

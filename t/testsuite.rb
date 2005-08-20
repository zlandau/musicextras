#!/usr/bin/ruby -w
# :nodoc all
#
# Test Suite for Musicextras

$:.unshift( File.join( '..', 'lib' ))
require 'test/unit'

require 'musicextras/mconfig'
MusicExtras::MConfig.instance['basedir'] = "test_dir"

dir = File.join(File.dirname(__FILE__), "TC_*.rb")
Dir[dir].each do |test|
  require test
end

puts 'NOTICE: run musicsites/testsuite.rb to test site plugins'

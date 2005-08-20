#!/usr/bin/ruby -w
# :nodoc all
#
# Test Suite for Musicextras

$:.unshift( File.join( '..', '..', 'lib' ))
require 'test/unit'

Dir['TC_*.rb'].each do |test|
  require test
end

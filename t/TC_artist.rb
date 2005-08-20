#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Artist
#

require 'test/unit'
require 'musicextras/artist'


class TC_Artist < Test::Unit::TestCase
  include MusicExtras

  def test_attributes
    assert_raises(ArgumentError) { Artist.new }

    artist = Artist.new('AnArtist')
    assert_equal('AnArtist', artist.name)
  end

  def test_inheritance
    assert_kind_of(DataAccessor, Artist.new('blah'))
  end

  def test_cache_values
    artist = Artist.new('MyArtist')

    assert_equal('MyArtist/', artist.cache_values('{ARTIST}/'))
  end
end

#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Album
#

require 'test/unit'
require 'musicextras/album'

class TC_Album < Test::Unit::TestCase
  include MusicExtras

  def test_initialize
    assert_raises(ArgumentError) { Album.new }
    assert_raises(ArgumentError) { Album.new('OneString') }

    album = Album.new('ATitle', 'AnArtist')
    assert_equal('ATitle', album.title)
    assert_equal('AnArtist', album.artist.name)
 
    album = Album.new('ATitle', Artist.new('AnArtist'))
    assert_equal('ATitle', album.title)
    assert_equal('AnArtist', album.artist.name)
  end

  def test_inheritance
    assert_kind_of(DataAccessor, Album.new('Blah', 'Blah'))
  end

  def test_cache_values
    album = Album.new('AnAlbum', 'AnArtist')

    assert_equal('/AnAlbum/', album.cache_values('/{ALBUM}/'))
    assert_equal('/AnArtist/', album.cache_values('/{ARTIST}/'))
    assert_equal('/AnArtist/AnAlbum/', album.cache_values('/{ARTIST}/{ALBUM}/'))
  end
end

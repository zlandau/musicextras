#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Song
#

require 'test/unit'
require 'musicextras/song'
require 'musicextras/artist'
require 'musicextras/dataaccessor'

class TC_Song < Test::Unit::TestCase
  include MusicExtras

  def test_inheritance
    assert_kind_of(DataAccessor, Song.new('blah', 'blah'))
  end

  def test_initialize
    song = Song.new('ATitle', 'AnArtist')
    assert_equal('ATitle', song.title)
    assert_equal('AnArtist', song.artist.name)
    
    song = Song.new('ATitle', Artist.new('AnArtist'))
    assert_equal('AnArtist', song.artist.name)
  end

  def test_with_album
    song = Song.with_album('ATitle', Album.new('AnAlbum', 'AnArtist'))
    assert_equal('ATitle', song.title)
    assert_kind_of(Artist, song.artist)
    assert_equal('AnArtist', song.artist.name)
    assert_kind_of(Album, song.album)
    assert_equal('AnAlbum', song.album.title)
  end

  def test_from_mp3_tag
    datadir = Dir["#{File.dirname(__FILE__)}/**/data"].to_s

    assert_raises(Errno::ENOENT) { Song.from_mp3_tag('doesnt exist') }
    assert_raises(Song::InvalidTagException) { Song.from_mp3_tag(File.join(datadir, "slide_notag.mp3")) }
    assert_raises(Song::InvalidTagException) { Song.from_mp3_tag(File.join(datadir, "slide_blanktag.mp3")) }

    song = Song.from_mp3_tag(File.join(datadir, "slide.mp3"))

    assert_equal('Test Title', song.title)
    assert_kind_of(Artist, song.artist)
    assert_equal('Test Artist', song.artist.name)
    assert_kind_of(Album, song.album)
    assert_equal('Test Album', song.album.title)
  end

  def test_cache_values
    song = Song.new('ATitle', 'AnArtist')

    assert_equal('ATitle', song.cache_values('{TITLE}'))
    assert_equal('AnArtist/ATitle.lyrics', song.cache_values('{ARTIST}/{TITLE}.lyrics'))

    song2 = Song.with_album('ATitle', Album.new('AnAlbum', 'AnArtist'))
    assert_equal('AnArtist/AnAlbum/ATitle.lyrics', song2.cache_values('{ARTIST}/{ALBUM}/{TITLE}.lyrics'))
   
    assert_equal('AnArtist//ATitle.lyrics', song.cache_values('{ARTIST}/{ALBUM}/{TITLE}.lyrics'))
  end

end

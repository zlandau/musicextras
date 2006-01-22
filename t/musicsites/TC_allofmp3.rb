#!/usr/bin/ruby -w
# :nodoc all
#
# Test For Allofmp3

require 'test/unit'
require 'musicextras/musicsites/allofmp3'

include MusicExtras

class TC_Allofmp3 < Test::Unit::TestCase

  def setup
    @site = Allofmp3.new

    @site.artist = Artist.new('')
    @site.album = Album.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('Allofmp3', @site.name)
    assert_equal('www.allofmp3.com', @site.url)
  end

  def test_get_artist_page
    @site.artist.name = 'Jimmy Buffett'
    assert_match(/.*Volcano.*/, @site.get_artist_page)

    @site.artist.name = 'ASDFBLAH'
    assert_nil(@site.get_artist_page)
  end

  def test_get_artist_image
    @site.artist.name = 'Jimmy Buffett'
    image = @site.image(@site.artist)
    assert(image)
    assert_equal('JFIF', image[6..9])
  end

  def test_get_album_url
    @site.artist.name = 'Jimmy Buffett'
    @site.album.title = 'Volcano'
    assert_equal("http://music.allofmp3.com/r2/Jimmy_Buffett/Volcano/group_7494/album_2/mcatalog.shtml?albref=14", @site.get_album_url)
    @site.album.title = 'Meet Me in Margaritaville'
    assert_equal("http://music.allofmp3.com/r2/Jimmy_Buffett/Meet_Me_in_Margaritaville__The_Ultimate_Collection/group_7494/album_3/mcatalog.shtml?albref=14", @site.get_album_url)
  end

  def test_get_album_cover_url
    @site.artist.name = 'Jimmy Buffett'
    @site.album.title = 'Volcano'
    assert_match(%r|covers/j/jimmy_buffett/volcano_\(1979\)/cover.jpg|, @site.get_album_cover_url)
  end

  def test_get_album_cover
    @site.artist = nil

    @site.album.artist.name = 'Jimmy Buffett'
    @site.album.title = 'Volcano'
    cover = @site.cover(@site.album)
    assert_equal('JFIF', cover[6..9])
  end
end

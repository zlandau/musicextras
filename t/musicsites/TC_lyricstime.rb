#!/usr/bin/ruby -w
# :nodoc all
#
# Test for LyricsTime
#

require 'test/unit'
require 'digest/md5'
require 'musicextras/musicsites/lyricstime'

include MusicExtras

class TC_LyricsTime < Test::Unit::TestCase

  def setup
    @site = LyricsTime.new
    @md5 = Digest::MD5

    @site.song = Song.new('', '')
    @site.song.album = Album.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('LyricsTime', @site.name)
    assert_equal('www.lyricstime.com', @site.url)
  end

  def test_get_artist_list_url
    @site.song.artist.name = 'Aerosmith'
    assert_equal('/A/', @site.get_artist_list_url)
    @site.song.artist.name = 'Agent 5 / 9'
    assert_equal('/A/', @site.get_artist_list_url)
    @site.song.artist.name = 'ZZ Top'
    assert_equal('/Z/', @site.get_artist_list_url)
    @site.song.artist.name = '98 Mute'
    assert_equal('/0-9/', @site.get_artist_list_url)
  end

  def test_get_artist_url
    @site.song.artist.name = 'Refused'
    assert_equal('/artist/refused/', @site.get_artist_url)
    @site.song.artist.name = 'Agent 5 / 9'
    assert_equal('/artist/agent-5-|-9/', @site.get_artist_url)
    @site.song.artist.name = 'ZZ Top'
    assert_equal('/artist/zz-top/', @site.get_artist_url)
    @site.song.artist.name = '98 Mute'
    assert_equal('/artist/98-mute/', @site.get_artist_url)
    @site.song.artist.name = 'Distillers'
    assert_equal('/artist/distillers/', @site.get_artist_url)
    @site.song.artist.name = 'IDontExist'
    assert_nil(@site.get_artist_url)
  end

  def test_get_song_url
    @site.song.artist.name = 'Refused'
    @site.song.title = 'Summer Holidays Vs. Punk Routine'
    assert_equal('/lyrics/43300.html', @site.get_song_url)
    @site.song.title = 'Summer Holidays Vs Punk Routine'
    assert_equal('/lyrics/43300.html', @site.get_song_url)

    @site.song.artist.name = 'Distillers'
    @site.song.title = 'I Am a Revenant'
    assert_equal('/lyrics/46914.html', @site.get_song_url)

    @site.song.artist.name = '98 Mute'
    @site.song.title = 'A. C. A. B.'
    assert_equal('/lyrics/40995.html', @site.get_song_url)
  end

  def test_get_album_cover_url
    @site.song.artist.name = 'Refused'
    @site.song.album.title = 'Songs To Fan The Flames Of Discontent'
    assert_equal('/Cover/3690.JPG', @site.get_album_cover_url)
    @site.song.album.title = 'Everlasting [ep]'
    assert_equal('/Cover/3688.JPG', @site.get_album_cover_url)
    @site.song.album.title = 'Doesnt Exist!'
    assert_equal(nil, @site.get_album_cover_url)
  end

  def test_get_album_cover
    @site.song.artist.name = 'Refused'
    @site.song.album.title = 'Songs To Fan The Flames Of Discontent'
    cover = @site.cover(Album.new('Songs To Fan The Flames Of Discontent', 'Refused'))
    assert_equal('fc52a4e24502205e8d32ec07dd864797',
    @md5.digest(cover).unpack("H*").to_s)
    @site.song.album.title = 'Everlasting [ep]'
    cover = @site.cover(@site.song.album)
    assert_equal('e9efcd775870267bb6253ef1858c2315',
    @md5.digest(cover).unpack("H*").to_s)
    @site.song.album.title = 'Unknown Album'   # that's really the name
    assert_nil(@site.cover(@site.album))
    @site.song.album.title = 'This Doesnt Exist'
    assert_nil(@site.cover(@site.album))
  end

  def test_lyrics
    lyrics = @site.lyrics(Song.new('Summer Holidays Vs. Punk Routine',
    'Refused'))
    assert_match(/.*I\'m tired of losing myself.*/, lyrics)
    assert_no_match(/.*<table.*/, lyrics)

    lyrics = @site.lyrics(Song.new('Lordy Lordy', 'Distillers'))
    assert_match(/.*This is a song from the heart.*/, lyrics)
    assert_nil(@site.lyrics(
	Song.new('This song does not exist', 'Refused')))
    assert_nil(@site.lyrics(
	Song.new('Whatever', 'This does not exist')))
    lyrics = @site.lyrics(Song.new('A. C. A. B.', '98 Mute'))
    assert_match(/.*Second grade school yard bully.*/, lyrics)
  end
end

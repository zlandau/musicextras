#!/usr/bin/ruby -w
# :nodoc all
#
# Test for LyricsNet

require 'test/unit'
require 'musicextras/musicsites/lyricsnet'

include MusicExtras

class TC_LyricsNet < Test::Unit::TestCase

  def setup
    @site = LyricsNet.new

    @site.song = Song.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('LyricsNet', @site.name)
    assert_equal('www.lyrics.net.ua', @site.url)
  end

  def test_get_artist_list_url
    @site.song.artist.name = 'Agent Orange'
    assert_equal('/a', @site.get_artist_list_url)
    @site.song.artist.name = 'ZZ Top'
    assert_equal('/z', @site.get_artist_list_url)
    @site.song.artist.name = '10000 Maniacs'
    assert_equal('/0', @site.get_artist_list_url)
  end

  def test_get_artist_url
    @site.song.artist.name = 'Tom Petty'
    assert_equal('/group/1049', @site.get_artist_url)
    @site.song.artist.name = 'The Cure'
    assert_equal('/group/2407', @site.get_artist_url)
    @site.song.artist.name = 'Does not exist'
    assert_equal(nil, @site.get_artist_url)
  end

  def test_get_song_url
    @site.song.artist.name = 'Tom Petty'
    @site.song.title = 'Free Fallin\''
    assert_equal('/song/30574', @site.get_song_url)
    @site.song.title = 'American Girl'
    assert_equal('/song/30485', @site.get_song_url)

    @site.song.artist.name = '98 Mute'
    @site.song.title = 'Wrong'
    assert_equal('/song/92105', @site.get_song_url)

    @site.song.artist.name = 'IDontExist'
    @site.song.title = 'Whatever'
    assert_nil(@site.get_song_url)
  end

  def test_lyrics
    lyrics = @site.lyrics(Song.new('Free Fallin\'', 'Tom Petty'))
    assert_match(/.*She\'s a good girl, loves her mam a.*/, lyrics)
    lyrics = @site.lyrics(Song.new('Doesnt Exist', 'Tom Petty'))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.new('Nope', 'Not Here'))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.new('Wrong', '98 Mute'))
    assert_match(/.*I know \'cause I was once.*/, lyrics)
  end
end

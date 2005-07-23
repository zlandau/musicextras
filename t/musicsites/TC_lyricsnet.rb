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
    @site.song.album = Album.new('', '')

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
    assert_equal('/lyrics/tom_petty.html', @site.get_artist_url)
    @site.song.artist.name = 'The Cure'
    assert_equal('/lyrics/the_cure.html', @site.get_artist_url)
    @site.song.artist.name = 'Does not exist'
    assert_equal(nil, @site.get_artist_url)
  end

  def test_get_song_url
    @site.song.artist.name = 'Tom Petty'
    @site.song.title = 'Free Fallin\''
    @site.song.album.title = "Full Moon Fever"
    #assert_equal('/song/30574', @site.get_song_url)
    assert_equal('/lyrics/tom_petty/full_moon_fever/free_fallin_.html', @site.get_song_url)
    @site.song.title = 'American Girl'
    @site.song.album.title = 'Greatest Hits'
    assert_equal('/lyrics/tom_petty/greatest_hits/american_girl.html', @site.get_song_url)

    @site.song.artist.name = '98 Mute'
    @site.song.album.title = '98 Mute'
    @site.song.title = 'Wrong'
    assert_equal('/lyrics/98_mute/98_mute/wrong.html', @site.get_song_url)

    @site.song.artist.name = 'IDontExist'
    @site.song.title = 'Whatever'
    assert_nil(@site.get_song_url)
  end

  def test_get_album_url
    @site.song.artist.name = "Tom Petty"
    @site.song.album.title = "Full Moon Fever"
    assert_match("/lyrics/tom_petty/full_moon_fever.html",
      @site.get_album_url)
  end

  def test_lyrics
    lyrics = @site.lyrics(Song.with_album('Free Fallin\'', Album.new("Full Moon Fever", "Tom Petty")))
    assert_match(/.*She\'s a good girl, loves her mam a.*/, lyrics)
    lyrics = @site.lyrics(Song.with_album('Doesnt Exist', Album.new("Full Moon Fever", 'Tom Petty')))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.with_album('Nope', Album.new("Naw", "Not")))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.with_album('Wrong', Album.new("98 Mute", "98 Mute")))
    assert_match(/.*I know \'cause I was once.*/, lyrics)
  end
end

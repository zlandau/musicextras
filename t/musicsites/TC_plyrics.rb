#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Plyrics

require 'test/unit'
require 'musicextras/musicsites/plyrics'

include MusicExtras

class TC_Plyrics < Test::Unit::TestCase

  def setup
    @site = Plyrics.new

    @site.song = Song.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('Plyrics', @site.name)
    assert_equal('www.plyrics.com', @site.url)
  end

  def test_get_artist_list_url
    @site.song.artist.name = 'Agent Orange'
    assert_equal('/a.html', @site.get_artist_list_url)
    @site.song.artist.name = 'Zeke'
    assert_equal('/z.html', @site.get_artist_list_url)
    @site.song.artist.name = '98 Mute'
    assert_equal('/19.html', @site.get_artist_list_url)
  end

  def test_get_artist_url
    @site.song.artist.name = 'Adolescents'
    assert_equal('/a/adolescents.html', @site.get_artist_url)
    @site.song.artist.name = 'Zero Down'
    assert_equal('/z/zerodown.html', @site.get_artist_url)
    @site.song.artist.name = '98 Mute'
    assert_equal('/19/98mute.html', @site.get_artist_url)
    @site.song.artist.name = 'Does not exist'
    assert_equal(nil, @site.get_artist_url)
  end

  def test_get_song_url
    @site.song.artist.name = 'Adolescents'
    @site.song.title = 'I Hate Children'
    assert_equal('/lyrics/adolescents/ihatechildren.html', @site.get_song_url)
    @site.song.title = 'No Way'
    assert_equal('/lyrics/adolescents/noway.html', @site.get_song_url)

    @site.song.artist.name = '98 Mute'
    @site.song.title = 'Wrong'
    assert_equal('/lyrics/98mute/wrong.html', @site.get_song_url)

    @site.song.artist.name = 'IDontExist'
    @site.song.title = 'Whatever'
    assert_nil(@site.get_song_url)
  end

  def test_lyrics
    lyrics = @site.lyrics(Song.new('I Hate Children', 'Adolescents'))
    assert_match(/.*Another child born*/, lyrics)
    assert_match(/.*Kill all children dead.*/, lyrics)
    lyrics = @site.lyrics(Song.new('Amoeba', 'Adolescents'))
    assert_match(/.*A one celled creature.*/, lyrics)
    lyrics = @site.lyrics(Song.new('DoesntExist', 'Adolescents'))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.new('Nope', 'Not Here'))
    assert_nil(lyrics)
    lyrics = @site.lyrics(Song.new('Wrong', '98 Mute'))
    assert_match(/.*I know \'cause I.*/, lyrics)
    lyrics = @site.lyrics(Song.new("I'm a wicked one", "Hives"))
    assert_match(/.*I'm a wicked one.*/, lyrics)
  end
  
  def test_cached_as
    song = Song.new('Title', 'Artist')

    assert_match(/.*artist\/title.lyrics/, song.cached_as(:lyrics))
  end

end

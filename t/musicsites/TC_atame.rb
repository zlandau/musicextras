#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Atame

require 'test/unit'
require 'musicextras/musicsites/atame'

include MusicExtras

class TC_Atame < Test::Unit::TestCase

  def setup
    @site = Atame.new

    @site.song = Song.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('Atame', @site.name)
    assert_equal('www.atame.org', @site.url)
  end

  def test_get_artist_list_url
    @site.song.artist.name = 'Abracadabra'
    assert_equal('/a/', @site.get_artist_list_url)

    @site.song.artist.name = '1280 almas'
    assert_equal('/_num/', @site.get_artist_list_url)
  end

  def test_get_artist_url
    @site.song.artist.name = 'Abracadabra'
    assert_equal('/a/abracadabra/', @site.get_artist_url)

    @site.song.artist.name = 'Zapato 3'
    assert_equal('/z/zapato_3/', @site.get_artist_url)

    @site.song.artist.name = '13 millas de libertad'
    assert_equal('/_num/13_millas_de_libertad/', @site.get_artist_url)

    @site.song.artist.name = 'Doesnt Exist'
    assert_nil(@site.get_artist_url)
  end

  def test_get_song_url
    @site.song.artist.name = 'Adamo'
    @site.song.title = 'Muy Juntos'
    assert_equal('/a/adamo/muy_juntos.txt', @site.get_song_url)
    @site.song.title = 'Mi Gran Noche'
    assert_equal('/a/adamo/mi_gran_noche.txt', @site.get_song_url)

    @site.song.artist.name = 'Safari'
    @site.song.title = 'Soy celoso'
    assert_equal('/s/safari/soy_celoso.txt', @site.get_song_url)
    @site.song.title = 'Coqueluche'
    assert_equal('/s/safari/coqueluche.txt', @site.get_song_url)

    @site.song.artist.name = 'Safari'
    @site.song.title = 'Doesnt Exist'
    assert_nil(@site.get_song_url)
  end

  def test_lyrics
    lyrics = @site.lyrics(Song.new('Muy cansado estoy', 'V8'))
    assert_match(/.*Recorriendo las calles.*/, lyrics)

    lyrics = @site.lyrics(Song.new('Esto que te doy', 'Eduardo Ortíz Tirado'))
    assert_match(/.*Toma mi vida.*/, lyrics)
  end
  
  def test_cached_as
    song = Song.new('Title', 'Artist')

    assert_match(/.*artist\/title.lyrics/, song.cached_as(:lyrics))
  end

end

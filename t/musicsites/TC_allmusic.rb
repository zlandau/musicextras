#!/usr/bin/ruby -w
# :nodoc all
#
# Test For AllMusic

require 'test/unit'
require 'musicextras/musicsites/allmusic'
require 'digest/md5'

include MusicExtras

class TC_AllMusic < Test::Unit::TestCase

  def setup
    @site = AllMusic.new
    @md5 = Digest::MD5

    @site.artist = Artist.new('')
    @site.album = Album.new('', '')

    Debuggable::setup()
  end

  def test_inheritence
    assert_kind_of(MusicSite, @site)
  end

  def test_class_vars
    assert_equal('AllMusic', @site.name)
    assert_equal('www.allmusic.com', @site.url)
  end

  def test_get_artist_page
    @site.artist.name = 'Refused'
    assert_match(/.*Swedish hardcore band Refused.*/, @site.get_artist_page)

    @site.artist.name = 'ASDFBLAH'
    assert_nil(@site.get_artist_page)

    @site.artist.name = 'they might be giants'
    assert_match(/.*Combining a knack.*/, @site.get_artist_page)

    @site.artist.name = '59 Times The Pain'
    assert_match(/.*Named in honor.*/, @site.get_artist_page)

    @site.artist.name = 'Forgotten'
    assert_match(/.*Creating radical themes.*/, @site.get_artist_page)

    @site.artist.name = 'Queen'
    assert_match(/.*Few bands embodied the pure excess.*/, @site.get_artist_page)

    @site.artist.name = 'Pixies'
    assert_match(/.*Combining jagged, roaring guitars.*/, @site.get_artist_page)
  end

  def test_get_artist_image
    @site.artist.name = 'Refused'
    image = @site.image(@site.artist)
    assert(image)
    assert_equal('JFIF', image[6..9])

    @site.artist.name = 'They Might Be Giants'
    image = @site.image(@site.artist)
    assert(image)
    assert_equal('JFIF', image[6..9])
  end

  def test_get_album_url
    # url changes every time, just make sure the url isn't nil
    @site.artist.name = 'Refused'
    @site.album.title = 'Songs To Fan The Flames Of Discontent'
    assert(@site.get_album_url)

    @site.artist.name = 'Pistol Grip'
    @site.album.title = 'The Shots From The Kalico Rose'
    assert(@site.get_album_url)

    @site.artist.name = 'Pistol Grip'
    @site.album.title = 'Shots From The Kalico Rose'
    assert(@site.get_album_url)

    @site.artist.name = 'Total Chaos'
    @site.album.title = 'Anthems from the Alleyway'
    assert(@site.get_album_url)
  end

  def test_get_album_cover_url
    @site.artist.name = 'Refused'
    @site.album.title = 'Songs To Fan The Flames Of Discontent'
    assert_equal('/00/amg/cov200/drg300/g312/g31276zhvt1.jpg', @site.get_album_cover_url)

    @site.artist.name = 'Pistol Grip'
    @site.album.title = 'Shots From The Kalico Rose'
    assert_equal('/00/amg/cov200/dre700/e757/e75709ddswo.jpg', @site.get_album_cover_url)
  end

  def test_get_album_cover
    @site.artist = nil
    @site.album.title = 'Songs To Fan The Flames Of Discontent'
    @site.album.artist.name = 'Refused'
    cover = @site.cover(@site.album)
    assert_equal('JFIF', cover[6..9])

    @site.album.title = 'Shots From The Kalico Rose'
    @site.album.artist.name = 'Pistol Grip'
    cover = @site.cover(@site.album)
    assert_equal('JFIF', cover[6..9])
  end

  def test_get_artist_bio
    @site.artist.name = 'Bad Religion'
    assert_match(/.*Out of all.*of Belief.*/m, @site.biography(@site.artist))
    
    @site.artist.name = '59 Times The Pain'
    assert_match(/.*Named in honor.*/, @site.biography(@site.artist))

    @site.artist.name = 'They Might Be Giants'
    assert_match(/.*Combining.*, No!.*/m, @site.biography(@site.artist))

    @site.artist.name = 'Refused'
    assert_match(/.*The Swedish hardcore band.*in music.*/m, @site.biography(@site.artist))

    @site.artist.name = 'Forgotten'
    assert_match(/.*Creating radical.*in May 2003.*/m, @site.biography(@site.artist))

    @site.artist.name = 'Doesnt exist'
    assert_nil(@site.biography(@site.artist))
  end

  def test_get_album_review
    @site.artist = nil

    @site.album.title = 'Suffer'
    @site.album.artist.name = 'Bad Religion'
    assert_match(/.*In early 2004.*Johnny Loftus/m, @site.review(@site.album))

    @site.album.title = 'Sing Loud Sing Proud'
    @site.album.artist.name = 'Dropkick Murphys'
    assert_match(/.*Boston\'s Dropkick.*Wilson/m, @site.review(@site.album))

    @site.album.title = 'Control Me'
    @site.album.artist.name = 'Forgotten'
    #assert_nil(@site.review(@site.album))
    assert_match(/.*no big secret to those.*/m, @site.review(@site.album))

    @site.album.title = 'Babylon and On'
    @site.album.artist.name = 'Squeeze'
    assert_match(/.*Following a brief.*Woodstra/m, @site.review(@site.album))
  end

  def test_years_active
    @site.artist.name = 'Elvis Presley'
    assert_equal("50s 60s 70s", @site.years_active(@site.artist))

    @site.artist.name = "Bad Religion"
    assert_equal("80s 90s 2000s", @site.years_active(@site.artist))
  end

  def test_tracks
    @site.album.artist.name = 'They Might Be Giants'
    @site.album.title = 'They Might Be Giants'
    tracks = @site.tracks(@site.album)
    assert_match(/1\. Everything Right Is Wrong Again/m, tracks)
    assert_match(/19\. Rhythm Section Want Ad/m, tracks)

    @site.album.artist.name = 'Pennywise'
    @site.album.title = 'Straight Ahead'
    tracks = @site.tracks(@site.album)
    assert_match(/1\. Greed/m, tracks)
    assert_match(/17\. Badge of Pride/m, tracks)
  end

  def test_album_year
    @site.artist = nil

    @site.album.title = 'Flood'
    @site.album.artist.name = 'They Might Be Giants'
    assert_equal("1990", @site.year(@site.album))

    @site.album.title = 'No Control'
    @site.album.artist.name = 'Bad Religion'
    assert_equal("1989", @site.year(@site.album))
  end

  def test_test
    assert(@site.test[0])
  end

end

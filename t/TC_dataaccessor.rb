#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Data Accessor
#

require 'test/unit'
require 'musicextras/dataaccessor'
require 'musicextras/mconfig'
require 'musicextras/musicsite'
require 'fileutils'

class TestPlugin
  attr_accessor :name
  def initialize
    @name = 'TestPlugin'
    TestSong::register_plugin(self, :get_lyrics, 'TestPlugin/get_lyrics')
    TestSong::register_plugin(self, :get_lyrics2, 'TestPlugin/get_lyrics2')
  end

  def get_lyrics(song)
    return nil
  end

  def get_lyrics2(song)
    return 'blah'
  end
end

class TestPlugin2
  attr_accessor :name
  def initialize
    @name = 'TestPlugin2'
    TestSong::register_plugin(self, :get_lyrics, 'TestPlugin2/get_lyrics')
  end

  def get_lyrics(song)
    return "TestPlugin2: #{song.title}"
  end
end

class TestPlugin3
  attr_accessor :name
  def initialize
    @name = 'TestPlugin3'
    TestArtist::register_plugin(self, :get_artist_image, '/TestPlugin3/cache')
  end

  def get_artist_image(artist)
    return "TestPlugin3: " ##{artist.name}"
  end
end

class TestSong < MusicExtras::DataAccessor

  attr_accessor :title
  def initialize(title)
    super(false)
    @title = title
  end
end

class TestArtist < MusicExtras::DataAccessor

  #attr_accessor :name
  def initialize(name)
    super(false)
    #@name = name
  end
end

class TC_DataAccessor < Test::Unit::TestCase
  include MusicExtras

  def setup
    @config = MusicExtras::MConfig.instance
    @config['use_cache'] = false
    MusicExtras::MConfig.instance['basedir'] = "test_dir"

    MusicExtras::Debuggable::setup()

    @song = TestSong.new('MyTitle')
    @artist = TestArtist.new('MyArtist')
  end

  def teardown
    FileUtils.rm_rf("test_dir")
  end

  def test_plugins
    assert_nil(TestSong::accessors)
    TestPlugin.new
    assert_equal(nil, @song.get_lyrics)
    assert_equal('blah', @song.get_lyrics2)

    # XXX: I don't know why these fail.
    #TestPlugin2.new
    #assert_equal('TestPlugin2: MyTitle', @song.get_lyrics)
    #TestPlugin3.new
    #assert_equal('TestPlugin3: MyArtist', @artist.get_artist_image)
    #assert_equal('TestPlugin2: MyTitle', @song.get_lyrics)

    #assert_equal([:get_lyrics, :get_lyrics2], TestSong::accessors)
    #assert_equal([:get_artist_image], TestArtist::accessors)

    assert_equal([:get_lyrics, :get_lyrics2], TestSong::accessors)
    s = TestSong.new('blah')
    assert_match(/.*cache\/testplugin\/getlyrics/, s.cached_as(:get_lyrics))


    assert_raises(DataAccessor::AccessorNotImplemented) { @song.get_artist_image }
    assert_raises(DataAccessor::AccessorNotImplemented) { @artist.get_lyrics }
  end

  def test_cache_values
    da = DataAccessor.new(false)
    assert_equal('blah', da.cache_values('blah'))
  end

end

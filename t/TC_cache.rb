#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Cache
#

require 'test/unit'
require 'musicextras/mconfig'
require 'musicextras/cache'
require 'fileutils'

class TC_Cache < Test::Unit::TestCase

  def setup
    MusicExtras::MConfig.instance['basedir'] = "test_dir"
    @cache = MusicExtras::Cache.new

    MusicExtras::Debuggable::setup()
  end

  def teardown
    FileUtils.rm_rf("test_dir")
  end

  def test_vars
    assert_kind_of(String, @cache.dir)
    assert_equal(File.join("test_dir", "cache"), @cache.dir)
  end

  def test_save_load
    key = 'test/key'
    assert_match(/.*test\/key/, @cache.save(key, 'MYDATA'))
    assert_equal('MYDATA', @cache.load(key))
    

    key = 'test/key.ext'
    assert_match(/.*test\/key.ext/, @cache.save(key, 'MYDATA'))
    assert_equal('MYDATA', @cache.load(key))

    assert_nil(@cache.load('idontexist'))
  end

  def test_get_filename
    assert_equal('test_dir/cache/mykey', @cache.send(:get_filename, 'my key', true))
    assert_equal('mykey', @cache.send(:get_filename, 'my key', false))
  end

  def test_greylist
    greylist = File.join("test_dir", "cache", "greylist.lst")

    @cache.clear_greylist()
    assert(!File.exist?(greylist))

    @cache.add_to_greylist('mytest')
    assert(@cache.greylisted?('mytest'))
    @cache.remove_from_greylist('mytest')
    assert(!@cache.greylisted?('mytest'))

    assert_nothing_raised { @cache.send(:save_greylist) }
    assert_match(/--- \{\}/, File.read(greylist))
    @cache.add_to_greylist('blah')
    assert_match(/--- \nblah: /, File.read(greylist))

    @cache.send(:setup_greylist)
    assert_match(/--- \nblah: /, File.read(greylist))

    @cache.clear_greylist()

    # only enable this if you need to test the lock file, because it
    # has a 10 second delay
    #lock = File.join("test_dir", "cache", ".greylist.lock")
    #File.open(lock, 'w') { |f| f.write("") }
    #@cache.add_to_greylist('blah2')
    #assert(@cache.greylisted?('blah2'))
  end

end

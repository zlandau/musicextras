#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Config
#

require 'test/unit'
require 'musicextras/config'

class TC_Config < Test::Unit::TestCase
  def test_keys
    config = MusicExtras::Config.instance
    assert_raises(MusicExtras::Config::InvalidKey) { config['invalid'] }
    assert_raises(MusicExtras::Config::InvalidKey) { config['invalid'] = "hi" }
    begin
      config['invalid']
    rescue MusicExtras::Config::InvalidKey => e
      assert_match(/Invalid config term: invalid/, e.to_s)
    end

    basedir = config['basedir']
    config['basedir'] = "foobar"
    assert_equal("foobar", config['basedir'])
    config['basedir'] = basedir
  end

end

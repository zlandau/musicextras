#!/usr/bin/ruby -w
# :nodoc all
#
# Test for AccessorData
#

require 'test/unit'
require 'musicextras/accessordata'

class TC_AccessorData < Test::Unit::TestCase

  def setup
    @a = MusicExtras::AccessorData.new(self, :accessor_method, '/cache/path')

    MusicExtras::Debuggable::setup()
  end

  def accessor_method(param)
    return param
  end
  
  def test_attributes
    assert_equal(self, @a.plugin)
    assert_equal(:accessor_method, @a.accessor)
    assert_equal('/cache/path', @a.cache_path)
  end

  def test_run
    assert_equal('testparam', @a.run('testparam'))
  end

end

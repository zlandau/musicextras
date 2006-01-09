#!/usr/bin/ruby -w
# :nodoc all
#
# Test for MusicSite
#

require 'test/unit'
require 'musicextras/musicsite'

module MusicExtras
  class TestPlugin1 < MusicExtras::MusicSite
    register()
    NAME = 'TestPlugin1'
    URL = 'www.testplugin1.com'
    DESCRIPTION = 'First Test Plugin'

    def initialize
      super(NAME, URL)
    end
  end

  class TestPlugin2 < MusicExtras::MusicSite
    register()
    NAME = 'TestPlugin2'
    URL = 'www.testplugin2.com'
    DESCRIPTION = 'Second Test Plugin'

    def initialize
      super(NAME, URL)
    end
  end
end

class TC_MusicSite < Test::Unit::TestCase
  include MusicExtras

  def setup
    @site = MusicSite.new('MusicSite', 'MusicSiteDefaultURL')

    Debuggable::setup()
  end

  def test_attributes
    assert_equal('MusicSite', @site.name)
    assert_equal('MusicSiteDefaultURL', @site.url)

    assert_equal('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.2.1) Gecko/20030225', MusicSite::USERAGENTS['Mozilla'])
    assert_equal('Opera/6.0 (Linux 2.4.18 i686; U)  [en]', MusicSite::USERAGENTS['Opera'])
    assert_equal('Lynx/2.8.4dev.16 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6-beta3', MusicSite::USERAGENTS['Lynx'])
  end

  def test_to_s
    assert_equal('MusicSite [MusicSiteDefaultURL]', @site.to_s)
  end

  def test_match
    assert(@site.match?('nospaces', 'no spaces'))
  end

  
  def test_extract_text
    html = "HEADER JUNK\nMORE HEADERS\nThe Meat and Potatoes\n" +
           "FOOTER JUNK\nMORE FOOTER JUNK"
    assert_equal('The Meat and Potatoes', @site.extract_text(html,
                      /MORE HEADERS\n(.*?)\nFOOTER JUNK/m))

    html = "<html>\n<body>\n<p class=\"text\"><br>" +
           "all work and no play make<br>" +
           " homer something something<br>" +
           "<table>\n<tr>\n<td><br>" +
           "There was a young man from Spleen<br>" +
           "Who invented a wanking machine<br>" +
	   "On the 99th stroke, the fucking thing broke<br>" +
	   "And whipped his balls into cream<br>" +
	   "</td></tr></table>" +
	   "go crazy? don't mind if i do!<br>\n" +
	   "</body></html>\n"

    assert_equal("There was a young man from Spleen\n" +
                 "Who invented a wanking machine\n" +
		 "On the 99th stroke, the fucking thing broke\n" +
		 "And whipped his balls into cream\n",
		 @site.extract_text(html, /<table>\n(.*?)<\/td>/m))

    html = "whatever\n\n\n\nblahblah\n\n\n\n"
    assert_equal("whatever\n\nblahblah\n", 
                  @site.extract_text(html, /(.*)\n/m))

    html = "one\n\ntwo\n\nthree\n\nfour\n\n"
    assert_equal("one\ntwo\nthree\nfour\n",
          	  @site.extract_text(html, /(.*)\n/m))

    assert_nil(@site.extract_text("blahblah", /onetwo/))
  end

  class TestSite < MusicSite
    NAME = 'TestSite'
    URL = 'www.google.com'
    def initialize
      super(NAME, URL)
    end
  end

  class InvalidTestSite < MusicSite
    def initialize
      super('InvalidTestSite', 'www.idontexistandhoepfullyneverwill.info')
    end
  end

  def test_fetch_page_and_source
    t = TestSite.new
    assert_match(/.*Privacy\r\n  Policy.*/, t.fetch_page('/about.html'))
    assert_match(/.*Global Preferences.*/, t.fetch_page('/preferences?hl=en'))

    i = InvalidTestSite.new
    assert_raises(SocketError) { i.fetch_page('/whatever.html') }

    assert_match(/.*Yahoo.*/, t.fetch_page('http://www.yahoo.com'))

    assert_match(/.*Source: TestSite \[www.google.com\].*/m, t.source())

  end

  def test_plugins
    assert_equal(%w(TestPlugin1 TestPlugin2), MusicSite.plugins)
    found = false
    ObjectSpace.each_object(MusicExtras::TestPlugin1) { found = true }
    assert(!found)
    found = false
    MusicSite.activate_plugins(['TestPlugin1'])
    ObjectSpace.each_object(MusicExtras::TestPlugin1) { found = true }
    assert(found)
    MusicSite.activate_plugins()
    found1 = found2 = false
    ObjectSpace.each_object(MusicExtras::TestPlugin1) { found1 = true }
    ObjectSpace.each_object(MusicExtras::TestPlugin2) { found2 = true }
    assert(found1 && found2)

    begin
      MusicSite.activate_plugins(['Invalid'])
    rescue MusicExtras::MusicSite::InvalidPlugin => e
      assert_match(/Plugin does not exist: Invalid/, e.to_s)
    end
  end
end

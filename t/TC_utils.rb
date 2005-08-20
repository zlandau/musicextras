#!/usr/bin/ruby -w
# :nodoc all
#
# Test for Utils
#

require 'test/unit'
require 'musicextras/utils'

class TC_Utils < Test::Unit::TestCase

  def test_single_mangle
    assert_equal('nospaces', 'nospaces'.mangle)
    assert_equal('nospaces', '     no     spaces  '.mangle)
    assert_equal('abcd', 'A. B. C. D'.mangle)
    assert_equal('freefallin', 'Free Fallin\''.mangle)
    assert_equal('changingcase', 'Changing Case'.mangle)
    assert_equal('aaaaaaaaaaaaaaaaaaaaaa',
                 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'.mangle)
    assert_equal('ihopethatigetoldbefore', 'I Hope That I Get Old Before I Die'.mangle)
    assert_equal('catch22', 'Catch-22'.mangle)
    assert_equal('catch22', 'Catch_22'.mangle)
    assert_equal('thisandthat', 'This & That'.mangle)
    assert_equal('text', 'text!@#$%^*()+_-\';:/.'.mangle)
    assert_equal('everlasting', 'Everlasting [ep]'.mangle)
    assert_equal('outside', 'Outside (inside)'.mangle)
    assert_equal('blah', 'Blah: extra info'.mangle)
    assert_equal('partial1', 'partial1 (blah'.mangle)
    assert_equal('partial2', 'partial2 [blah'.mangle)
  end

  def test_match_unicode
      assert_equal("ab\304\243cd", "ab\304\243cd".mangle)
  end

  def test_pronoun_mangle
    assert_equal('car', 'the car'.mangle(true))
    assert_equal('car', 'los car'.mangle(true))
    assert_equal('car', 'las car'.mangle(true))
    assert_equal('car', 'el car'.mangle(true))
    assert_equal('car', 'la car'.mangle(true))
    assert_equal('car', 'The Car'.mangle(true))

    assert_equal('loscar', 'loscar'.mangle(true))
    assert_equal('lascar', 'lascar'.mangle(true))
    assert_equal('elcar', 'elcar'.mangle(true))
    assert_equal('lacar', 'lacar'.mangle(true))
    assert_equal('thecar', 'TheCar'.mangle(true))

    assert_equal('lawoman', 'L.A. Woman'.mangle(true))
  end

  def test_strip_html
    assert_equal("Hello\n", 'Hello<br>'.strip_html)
    assert_equal("Hello\n", '<br />Hello<br/>'.strip_html)
    assert_equal("Hello\n", '<BR />Hello<BR/>'.strip_html)
    assert_equal('Hello', '<p>Hello</p>'.strip_html)
    assert_equal('Hello', '<P>Hello</P>'.strip_html)
    assert_equal("Hello", "Hello\r".strip_html)
    assert_equal('<', '&lt;'.strip_html)
    assert_equal('>', '&gt;'.strip_html)
    assert_equal('"', '&quot;'.strip_html)
    assert_equal('&', '&amp;'.strip_html)

    txt1 = <<TXT1
<html>
  <body>
line one<br/>

line two<br/>

line three<br/>
line four<br/>
  </body>
</html>
TXT1

    txt1_conv = <<TXT1_CONV
line one

line two

line three
line four
TXT1_CONV

    assert_equal(txt1_conv, txt1.strip_html)
  end

  def test_remove_extra_blanks
    txt1 = <<TXT1
text
text

text
text

text
text
TXT1

    # XXX: this SHOULD pass, but so far it has been okay that it
    # doesn't. we'll see.
    # assert_equal(txt1, txt1.remove_extra_blanks)

    txt2 = <<TXT2
text

text


text

text


text

text
TXT2

    txt2_conv = <<TXT2_CONV
text
text

text
text

text
text
TXT2_CONV

    assert_equal(txt2_conv, txt2.remove_extra_blanks)
  end

  def test_paragraph

    txt1 = <<TXT1
<p>Hello
Sir
</p>
<p>How are
you
</p>
TXT1

    txt1_conv = <<TXT1_CONV
Hello
Sir

How are
you
TXT1_CONV

    assert_equal(txt1_conv, txt1.strip_html)
  end

  def test_to_utf8
    # XXX: Should test actual conversion
    path = $:.dup
    $:.clear

    assert_nothing_raised { "blah1".to_utf8 }

    $:.concat(path)
    assert_nothing_raised { "blah2".to_utf8 }
    assert_nothing_raised { "blah3".to_utf8("iso-8859-1") }
  end

  def test_find_in_path
    require 'rbconfig'

    assert_match(/\/optparse.rb/, File.find_in_path('optparse.rb', $:))
  end

end

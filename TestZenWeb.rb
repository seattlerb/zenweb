#!/usr/local/bin/ruby -w

require 'ZenWeb'
require 'runit/testcase'

# REFACTOR: get subclasses to use this
class ZenTest < RUNIT::TestCase

  def setup
    @datadir = "test"
    @htmldir = "testhtml"
    @sitemapUrl = "/SiteMap.html"
    @url = "/~ryand/index.html"
    @web = ZenWebsite.new(@sitemapUrl, @datadir, @htmldir)
    @doc = ZenDocument.new(@url, @web)
    @content = @doc.renderContent
  end

  def teardown
    if (test(?d, @htmldir)) then
      #`rm -rf #{@htmldir}` unless $DEBUG
    end
  end

end

############################################################
# ZenWebsite:

class TestZenWebsite < RUNIT::TestCase

  def setup
    @url = "/SiteMap.html"
    @datadir = "test"
    @htmldir = "testhtml"
    @web = ZenWebsite.new(@url, @datadir, @htmldir)
  end

  def teardown
    if (test(?d, @htmldir)) then
      #`rm -rf #{@htmldir}` unless $DEBUG
    end
  end

  def test_initialize1
    # TODO: add a test for a url w/o leading slash
    # TODO: def initialize(sitemapUrl, datadir, htmldir)

    begin
      @web = ZenWebsite.new("/doesn't exist", @datadir, @htmldir)
    rescue
      assert_equals("ArgumentError", $!.class.to_s)
    else
      assert(FALSE, "Bad url should throw exception")
    end
    
  end

  def test_initialize2
    # TODO: add a test for a url w/o leading slash

    begin
      @web = ZenWebsite.new(@url, "/doesn't exist", @htmldir)
    rescue
      assert_equals("ArgumentError", $!.class.to_s)
    else
      assert(FALSE, "Bad datadir should throw exception")
    end
    
  end

  def test_initialize3

    # missing a leading slash
    # TODO: what should happen if it is missing a leading slash?
    begin
      @web = ZenWebsite.new("SiteMap.html", @datadir, @htmldir)
    rescue
      assert_equals("ArgumentError", $!.class.to_s)
    else
      assert(FALSE, "Bad url should throw exception")
    end
    
  end

  def util_checkContent(path, expected)
    assert(test(?f, path),
	   "File '#{path}' must exist")
    file = IO.readlines(path).join('')
    assert_not_nil(file.index(expected),
	   "File '#{path}' must have correct content")
  end

  def test_render

    @web.renderSite

    assert(test(?d, @htmldir),
	   "HTML directory must be created by renderSite")

    util_checkContent(@htmldir + "/index.html",
		      "this is the url: /index.html")

    util_checkContent(@htmldir + "/SiteMap.html",
		      "/~ryand/stuff/index.html")

    util_checkContent(@htmldir + "/Something.html",
		      "this is the url: /Something.html")

    util_checkContent(@htmldir + "/ryand/index.html",
		      "Everything is separated by paragraphs")

    util_checkContent(@htmldir + "/ryand/blah.html",
		      "this is the url: /~ryand/blah.html")

    util_checkContent(@htmldir + "/ryand/stuff/index.html",
		      "this is the url: /~ryand/stuff/index.html")

  end

  def test_index_accessor
    assert_not_nil(@web[@url],
		   "index accessor must return the sitemap")
    assert_nil(@web["doesn't exist"],
	       "index accessor must return nil for bad urls")
  end

end

############################################################
# ZenDocument

class TestZenDocument < ZenTest

  def test_initialize
    # TODO: def initialize(url, website, datadir, htmldir)
  end

  def test_subpages
    @web.renderSite
    @doc = @web[@url]
    assert_equals([ '/~ryand/blah.html', '/~ryand/stuff/index.html' ],
		  @doc.subpages.sort)
  end

  # TODO: move these renderer specific things to their test classes.

  def test_render
    # TODO: test_render
  end

  def test_parentURL
    # 1 level deep
    @doc = ZenDocument.new("/Something.html", @web)
    assert_equals("/index.html", @doc.parentURL())

    # 2 levels deep - index
    @doc = ZenDocument.new("/ryand/index.html", @web)
    assert_equals("/index.html", @doc.parentURL())

    # 2 levels deep
    # yes, using metadata.txt is cheating, but it is a valid file...
    @doc = ZenDocument.new("/ryand/metadata.txt", @web)
    assert_equals("/ryand/index.html", @doc.parentURL())

    # 1 levels deep with a tilde
    @doc = ZenDocument.new("/~ryand/index.html", @web)
    # TODO: at this point, I think this is correct. This may become a variable.
    assert_equals("/index.html", @doc.parentURL())

    # 2 levels deep with a tilde
    @doc = ZenDocument.new("/~ryand/stuff/index.html", @web)
    assert_equals("/~ryand/index.html", @doc.parentURL())
  end

  def test_createList1

    assert_equal(["line 1", "line 2"],
		 @doc.createList("line 1\nline 2\n"))
  end

  def test_createList2

    assert_equals([ "line 1", 
		    [ "line 1.1", "line 1.2" ], 
		    "line 2", 
		    [ "line 2.1",
		      [ "line 2.1.1" ] ] ],
		  @doc.createList("line 1\n\tline 1.1\n\tline 1.2\n" +
				  "line 2\n\tline 2.1\n\t\tline 2.1.1"))
  end

  def test_parent
    parent = @doc.parent

    assert_not_nil(parent,
		   "Parent must not be nil")

    assert_equal("/index.html", parent.url,
		 "Parent url must be correct")
  end

  def test_metadata
    # TODO: def metadata
  end

  def test_getDir
    # TODO: def getDir()
  end

  def test_getDataPath
    assert_equals("test/ryand/index", @doc.datapath)
  end

  def test_getHtmlPath
    assert_equals("testhtml/ryand/index.html", @doc.htmlpath)
  end

end

############################################################
# ZenSitemap

class TestZenSitemap < RUNIT::TestCase

  def setup
    @url = "/SiteMap.html"
    @web = ZenWebsite.new(@url, "test", "testhtml")
    @doc = @web[@url]
  end

  def test_initialize
    # TODO: def initialize(url, website, datadir, htmldir)
  end

  def test_getDocuments
    # TODO: def getDocuments()
  end

  def test_sitemap_content
    content = @doc.renderContent

    assert_not_nil(content.index("<HTML>"), "Must render some form of HTML")
  end
end

class TestGenericRenderer < ZenTest

  def test_initialize
    # TODO: def initialize(document)
  end

  def test_push
    # TODO: def push(obj)
  end

  def test_unshift
    # TODO: def unshift(obj)
  end

  def test_render
    # TODO: def render(content)
  end

  def test_access
    # TODO: def [](key)
  end
end

class TestHtmlTemplateRenderer < ZenTest

  def test_renderContent_html_and_head
    assert_not_nil(@content.index("<HTML>
<HEAD>
<TITLE>Ryan's Homepage: Version 2.0</TITLE>
<LINK REV=\"MADE\" HREF=\"mailto:ryand-web@zenspider.com\">
<META NAME=\"rating\" CONTENT=\"general\">
<META NAME=\"GENERATOR\" CONTENT=\"ZenWeb 2.0.0\">
<META NAME=\"author\" CONTENT=\"Ryan Davis\">
<META NAME=\"copyright\" CONTENT=\"1996-2001, Zen Spider Software\">
</HEAD>
<BODY>
<P>
<A HREF=\"/SiteMap.html\"><STRONG>Sitemap</STRONG></A> || <A HREF=\"/index.html\">My Homepage</A>
 / Ryan's Homepage</P>
<H1>Ryan's Homepage</H1>
<H2>Version 2.0</H2>
<HR SIZE=\"3\" NOSHADE>"),
	   "Must render the HTML header and all appropriate metadata")
  end

  def test_renderContent_foot
    assert(@content =~ %r,</BODY>\n</HTML>\n,,
	   "Must render HTML footer")
  end

end

class TestTextToHtmlRenderer < ZenTest

  def test_renderContent_headers
    assert(@content =~ %r,<H2>Head 2</H2>,,
	   "Must render H2 from **")

    assert(@content =~ %r,<H3>Head 3</H3>,,
	   "Must render H3 from ***")

    assert(@content =~ %r,<H4>Head 4</H4>,,
	   "Must render H4 from ****")

    assert(@content =~ %r,<H5>Head 5</H5>,,
	   "Must render H5 from *****")

    assert(@content =~ %r,<H6>Head 6</H6>,,
	   "Must render H6 from ******")

  end

  def test_renderContent_list1

    assert_not_nil(@content.index("<UL>\n  <LI>Lists (should have two items).</LI>\n  <LI>Continuted Lists.</LI>\n</UL>"),
	   "Must render normal list from +")
  end

  def test_renderContent_list2
    assert_not_nil(@content.index("<UL>\n  <LI>Another List (should have a sub list).</LI>\n  <UL>\n    <LI>With a sub-list</LI>\n    <LI>another item</LI>\n  </UL>\n</UL>"),
	   "Must render compound list from indented +'s")
  end

  def test_renderContent_metadata
    assert(@content =~ %r,Glossary lookups for 42 and some string \(see metadata.txt for a hint\)\.\s+key99 should not look up\.,,
	   "Must render metadata lookups from \#\{key\}")
  end

  def test_renderContent_small_rule
    assert(@content =~ %r,^<HR SIZE="1" NOSHADE>$,,
	   "Must render small rule from ---")
  end

  def test_renderContent_big_rule
    assert(@content =~ %r,^<HR SIZE="2" NOSHADE>$,,
	   "Must render big rule from ===")
  end

  def test_renderContent_paragraph1
    assert(@content =~ %r,^<P>Paragraphs can contain <A HREF="http://www\.ZenSpider\.com/ZSS/ZenWeb/">www\.ZenSpider\.com /ZSS /ZenWeb</A> and <A HREF="mailto:zss@ZenSpider\.com">zss@ZenSpider\.com</A> and they will automatically be converted\..*?</P>$,,
	   "Must render paragraph from a single line")
  end

  def test_renderContent_paragraph2
    assert(@content =~ %r;^<P>Likewise, two lines side by side\s+are considered one paragraph\..*?</P>$;,
	   "Must render paragraph from multiple lines")
  end

  def test_renderContent_paragraph3
     assert(@content =~ %r@Don\'t forget less-than "&lt;" &amp; greater-than "&gt;", but only if backslashed.</P>$@,
	   "Must convert special entities")
  end

  def test_renderContent_paragraph4
    assert(@content =~ %r;Supports <I>Embedded HTML</I>\.</P>$;,
	   "Must render paragraph from multiple lines")
  end

  def test_renderContent_paragraph5
    assert(@content =~ %r;Supports <A HREF=\"http://www.yahoo.com\">Unaltered urls</A> as well\.</P>$;,
	   "Must render full urls without conversion")
  end

  def test_renderContent_pre

    assert_not_nil(@content.index("<PRE>PRE blocks are paragraphs that are indented two spaces on each line.
The two spaces will be stripped, and all other indentation will be left
alone.
   this allows me to put things like code examples in and retain
       their formatting.</PRE>"),
	   "Must render PRE blocks from indented paragraphs")
  end

  def test_navbar
    # TODO: def navbar
  end
end

class TestFooterRenderer < ZenTest
  def test_render
    # TODO: def render(content)
  end
end

class TestHeaderRenderer < ZenTest
  def test_render
    # TODO: def render(content)
  end
end

############################################################
# Metadata

class TestMetadata < RUNIT::TestCase

  def setup
    @file = "hash." + $$.to_s
    @hash = Metadata.new("test/ryand")
  end

  def teardown
    if (test(?f, @file)) then
      File.unlink(@file)
    end
  end

  def test_initialize
    # TODO: def initialize(directory, toplevel = "/")
  end
  def test_save
    # TODO: def save(file)
  end
  def test_loadFromDirectory
    # TODO: def loadFromDirectory(directory, toplevel, count = 1)
  end
  def test_load
    # TODO: def load(file)
  end

  def test_core
    # this asserts that the values in the child are correct.
    assert_equal(42, @hash["key1"])
    assert_equal("some string", @hash["key2"])
    assert_equal("another string", @hash["key3"])
  end

  def test_parenthood
    # this is defined in the parent, but not the child
    assert_equal([ 'TextToHtmlRenderer', 'HtmlTemplateRenderer' ],
		 @hash["renderers"])
  end

end

############################################################
# The Test Suite:

class TestAll 
  def TestAll.suite
    suite = RUNIT::TestSuite.new

    suite.add_test(TestZenWebsite.suite)
    suite.add_test(TestZenDocument.suite)
    suite.add_test(TestZenSitemap.suite)
    suite.add_test(TestGenericRenderer.suite)
    suite.add_test(TestHtmlTemplateRenderer.suite)
    suite.add_test(TestTextToHtmlRenderer.suite)
    suite.add_test(TestFooterRenderer.suite)
    suite.add_test(TestHeaderRenderer.suite)
    suite.add_test(TestMetadata.suite)

    return suite
  end
end

############################################################
# Main:

if __FILE__ == $0
  require 'runit/cui/testrunner'

  unless ($DEBUG) then
    suite = TestAll.suite
  else
    suite = RUNIT::TestSuite.new
    suite.add_test(TestZenDocument.new("test_parent", "TestZenDocument"))
  end

  RUNIT::CUI::TestRunner.run(suite)
end


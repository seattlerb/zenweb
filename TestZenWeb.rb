#!/usr/local/bin/ruby -w

$TESTING = TRUE

require 'ZenWeb'
require 'ZenWeb/SitemapRenderer'
require 'ZenWeb/TocRenderer'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

class ZenTest < Test::Unit::TestCase

  def set_up
    @datadir = "test"
    @htmldir = "testhtml"
    @sitemapUrl = "/SiteMap.html"
    @url = "/~ryand/index.html"
    @web = ZenWebsite.new(@sitemapUrl, @datadir, @htmldir)
    @doc = @web[@url]
    @content = @doc.renderContent
  end

  def tear_down
    if (test(?d, @htmldir)) then
      `rm -rf #{@htmldir}` 
      # unless $DEBUG
    end
  end

end

############################################################
# ZenWebsite:

class TestZenWebsite < ZenTest

  def tear_down
    if (test(?d, @htmldir)) then
      `rm -rf #{@htmldir}`
      # unless $DEBUG
    end
  end

  def test_initialize_bad_sitemap
    util_initialize("/doesn't exist", @datadir, @htmldir)
  end

  def test_initialize_missing_datadir
    util_initialize(@sitemapUrl, "/doesn't exist", @htmldir)
  end

  def test_initialize_missing_leading_slash
    # missing a leading slash
    util_initialize("SiteMap.html", @datadir, @htmldir)
  end

  def test_initialize_tilde
    # this should work fine
    util_initialize("/~ryand/SiteMap.html", @datadir, @htmldir, false)
  end

  def util_initialize(sitemap_url, data_dir, html_dir, should_fail=true)
    if (should_fail) then
      assert_raises(ArgumentError, "Must throw an ArgumentError") {
	ZenWebsite.new(sitemap_url, data_dir, html_dir)
      }
    else
      assert_nothing_raised("Must not throw any exceptions") {
	ZenWebsite.new(sitemap_url, data_dir, html_dir)
      }
    end
  end

  def util_checkContent(path, expected)
    assert(test(?f, path),
	   "File '#{path}' must exist")
    file = IO.readlines(path).join('')
    assert_not_nil(file.index(expected),
	   "File '#{path}' must have correct content")
  end

  def test_renderSite

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

  def test_index
    assert_not_nil(@web.sitemap,
		   "index accessor must return the sitemap")
    assert_nil(@web["doesn't exist"],
	       "index accessor must return nil for bad urls")
  end

  def test_datadir
    assert(false, 'Need to write test_datadir tests')
  end

  def test_doc_order
    assert(false, 'Need to write test_doc_order tests')
  end

  def test_documents
    assert(false, 'Need to write test_documents tests')
  end

  def test_htmldir
    assert(false, 'Need to write test_htmldir tests')
  end

  def test_sitemap
    assert(false, 'Need to write test_sitemap tests')
  end

end

############################################################
# ZenDocument

class TestZenDocument < ZenTest

  def set_up
    super
    @expected_datapath = "test/ryand/index"
    @expected_htmlpath = "testhtml/ryand/index.html"
    @expected_dir = "test/ryand"
    @expected_subpages = [ '/~ryand/blah.html', '/~ryand/stuff/index.html' ]
  end

  def test_initialize_good_url
    begin
      ZenDocument.new("/Something.html", @web)
    rescue
      assert(FALSE, "good url must not throw an exception")
    else
      # this is good.
    end
  end

  def test_initialize_missing_ext
    # missing extension
    begin
      ZenDocument.new("/Something", @web)
    rescue
      assert(FALSE, "missing extension must not throw an exception")
    else
      # this is good
    end
  end

  def test_initialize_missing_slash
    # missing slash url
    begin
      ZenDocument.new("Something.html", @web)
    rescue ArgumentError
      # this is good
    rescue
      assert(FALSE, "missing slash produced the wrong type of exception")
    else
      assert(FALSE, "missing slash should have thrown an exception")
    end
  end

  def test_initialize_bad_url
    # bad url
    begin
      ZenDocument.new("/missing.html", @web)
    rescue ArgumentError
      # this is good
    rescue
      assert(FALSE, "missing document produced the wrong type of exception")
    else
      assert(FALSE, "missing document should have thrown an exception")
    end
  end

  def test_initialize_nil_website
    begin
      ZenDocument.new("Something.html", nil)
    rescue ArgumentError
      # this is good
    rescue
      assert(FALSE, "nil website produced the wrong type of exception")
    else
      assert(FALSE, "nil website should have thrown an exception")
    end
  end

  def test_subpages
    @web.renderSite
    @doc = @web[@url]
    assert_equal(@expected_subpages,
		  @doc.subpages.sort)
  end

  def test_render
    file = @doc.htmlpath
    if (test(?f, file)) then
      File.delete(file)
    end

    @doc.render

    assert(test(?f, file), "document must render in correct location")
  end

  def test_renderContent_bad
    @doc = @web.sitemap
    @doc['renderers'] = [ 'NonExistantRenderer' ]

    begin
      @doc.renderContent
    rescue Exception
      assert_equal("NotImplementedError", $!.class.name,
		    "renderContent must throw a NotImplementError.")
    else
      assert(FALSE,
	     "renderContent must throw an exception if renderer doesn't exist")
    end
  end

  def test_newerThanTarget_missing
    # setup, delete target file, call function. Must return true

    if not test ?f, @doc.datapath then
      puts "datafile does not exist"
    end

    if test ?f, @doc.htmlpath then
      File.delete(@doc.htmlpath)
    end

    assert(@doc.newerThanTarget, 
	   "doc must be newer because target is missing")
  end

  def test_newerThanTarget_yes
    util_newerThanTarget(true)
  end

  def test_newerThanTarget_no
    util_newerThanTarget(false)
  end

  def test_newerThanTarget_sitemap
    util_newerThanTarget(false, true)
    util_newerThanTarget(true,  true)
  end

  def util_newerThanTarget(page_is_newer, sitemap_is_newer=false)

    @web.renderSite
    
    doc_htmlpath = @doc.htmlpath
    doc_datapath = @doc.datapath

    assert(test(?f, doc_htmlpath),
	   "htmlpath must exist at #{doc_htmlpath}")
    assert(test(?f, doc_datapath),
	   "datapath must exist at #{doc_datapath}")

    time_old = '200101010000'
    time_new = '200101020000'

    # unify times
    `touch -t #{time_old} #{doc_datapath} #{doc_htmlpath}`

    # update page
    if page_is_newer then `touch -t #{time_new} #{doc_datapath}` end

    # test
    if (page_is_newer) then
      assert(@doc.newerThanTarget,
	     "doc must be newer: #{page_is_newer} #{sitemap_is_newer}")
    else
      assert(! @doc.newerThanTarget,
	     "doc must not be newer")
    end
  end

  def test_parentURL
    # 1 level deep
    @doc = ZenDocument.new("/Something.html", @web)
    assert_equal("/index.html", @doc.parentURL())

    # 2 levels deep - index
    @doc = ZenDocument.new("/ryand/index.html", @web)
    assert_equal("/index.html", @doc.parentURL())

    # 2 levels deep
    # yes, using metadata.txt is cheating, but it is a valid file...
    @doc = ZenDocument.new("/ryand/metadata.txt", @web)
    assert_equal("/ryand/index.html", @doc.parentURL())

    # 1 levels deep with a tilde
    @doc = ZenDocument.new("/~ryand/index.html", @web)
    assert_equal("/index.html", @doc.parentURL())

    # 2 levels deep with a tilde
    @doc = ZenDocument.new("/~ryand/stuff/index.html", @web)
    assert_equal("/~ryand/index.html", @doc.parentURL())
  end

  def test_parent
    parent = @doc.parent

    assert_not_nil(parent,
		   "Parent must not be nil")

    assert_equal("/index.html", parent.url,
		  "Parent url must be correct")
  end

  def test_dir
    assert_equal(@expected_dir, @doc.dir)
  end

  def test_datapath
    assert_equal(@expected_datapath, @doc.datapath)
  end

  def test_htmlpath
    assert_equal(@expected_htmlpath, @doc.htmlpath)
  end

  def test_metadata_lookup
    assert_nil(@doc['nothing'])

    @doc = ZenDocument.new("/Something.html", @web)
    assert_equal(['StandardRenderer', 'RelativeRenderer'],
		 @doc['renderers'])
  end

  def test_addSubpage
    assert(false, 'Need to write test_addSubpage tests')
  end

  def test_content
    assert(false, 'Need to write test_content tests')
  end

  def test_content=
      assert(false, 'Need to write test_content= tests')
  end

  def test_datadir
    assert(false, 'Need to write test_datadir tests')
  end

  def test_fulltitle
    assert(false, 'Need to write test_fulltitle tests')
  end

  def test_htmldir
    assert(false, 'Need to write test_htmldir tests')
  end

  def test_index
    assert(false, 'Need to write test_index tests')
  end

  def test_index_equals
    assert(false, 'Need to write test_index_equals tests')
  end

  def test_metadata
    assert(false, 'Need to write test_metadata tests')
  end

  def test_newerThanTarget
    assert(false, 'Need to write test_newerThanTarget tests')
  end

  def test_parseMetadata
    assert(false, 'Need to write test_parseMetadata tests')
  end

  def test_renderContent
    assert(false, 'Need to write test_renderContent tests')
  end

  def test_url
    assert(false, 'Need to write test_url tests')
  end

  def test_website
    assert(false, 'Need to write test_website tests')
  end
end

############################################################
# ZenSitemap

class TestZenSitemap < TestZenDocument

  def set_up
    super
    @url = @sitemapUrl
    @web = ZenWebsite.new(@url, "test", "testhtml")
    @doc = @web[@url]
    @content = @doc.renderContent

    @expected_datapath = "test/SiteMap"
    @expected_dir = "test"
    @expected_htmlpath = "testhtml/SiteMap.html"
    @expected_subpages = []

    @expected_docs = ([ "/index.html",
			"/SiteMap.html",
			"/Something.html",
			"/~ryand/index.html",
			"/~ryand/blah.html",
			"/~ryand/stuff/index.html"])
  end

  def test_documents
    docs = @doc.documents

    @expected_docs.each { | url |
      assert(docs.has_key?(url),
	     "Sitemap's documents must include #{url}")

      assert_equal(url != "/SiteMap.html" ? ZenDocument : ZenSitemap,
		   docs[url].class,
		   "Document #{url} must be the correct class")
    }
  end

  def test_doc_order
    assert_equal(@expected_docs,
		 @doc.doc_order,
		 "Sitemap's document order must be correct")
  end

# HACK: relocate to SitemapRenderer
#  def test_renderContent
#    expected = "<H2>There are 6 pages in this website.</H2>\n<HR SIZE=\"3\" NOSHADE>\n\n<UL>\n  <LI><A HREF=\"/index.html\">My Website: Subtitle</A></LI>\n  <LI><A HREF=\"/SiteMap.html\">Sitemap: There are 6 pages in this website.</A></LI>\n  <LI><A HREF=\"/Something.html\">Something</A></LI>\n  <LI><A HREF=\"/~ryand/index.html\">Ryan's Homepage: Version 2.0</A></LI>\n  <UL>\n    <LI><A HREF=\"/~ryand/blah.html\">blah</A></LI>\n    <LI><A HREF=\"/~ryand/stuff/index.html\">my stuff</A></LI>\n  </UL>\n</UL>"
#
#    assert_not_nil(@content.index(expected) > 0,
#		   "Must render some form of HTML")
#  end
end

############################################################
# Metadata

class TestMetadata < Test::Unit::TestCase

  def set_up
    @hash = Metadata.new("test/ryand")
  end

  def tear_down
  end

  def test_initialize_good
    begin
      @hash = Metadata.new("test/ryand", "/")
    rescue
      assert_fail("Good init shall not throw an exception")
    else
      # this is good
    end
  end

  def test_initialize_bad_path
    assert_raises(ArgumentError, "bad path shall throw an ArgumentError") {
      @hash = Metadata.new("bad_path", "/")
    }
  end

  def test_initialize_bad_top
    assert_raises(ArgumentError, "bad top shall throw an ArgumentError") {
      @hash = Metadata.new("test/ryand", "somewhereelse")
    }
  end

  def test_initialize_too_deep_top
    assert_raises(ArgumentError, "deeper top shall throw an ArgumentError") {
      @hash = Metadata.new("test/ryand", "test/ryand/stuff")
    }
  end

  def test_loadFromDirectory
    @hash = Metadata.new("test")
    assert_equal(24, @hash["key1"])
    @hash.loadFromDirectory("test/ryand", '.')
    assert_equal(42, @hash["key1"])
  end

  def test_load
    # initial load should be 
    @hash = Metadata.new("test")
    assert_equal(24, @hash["key1"])
    @hash.load("test/ryand/metadata.txt")
    assert_equal(42, @hash["key1"])
  end

  def test_index_child
    # this asserts that the values in the child are correct.
    assert_equal(42, @hash["key1"])
    assert_equal("some string", @hash["key2"])
    assert_equal("another string", @hash["key3"])
  end

  def test_index_parent
    # this is defined in the parent, but not the child
    assert_equal([ 'StandardRenderer', 'RelativeRenderer' ],
		 @hash["renderers"])
  end

end

############################################################
# All Renderer Tests:

class TestGenericRenderer < ZenTest

  def set_up
    super
    @renderer = GenericRenderer.new(@doc)
  end

  def test_push
    assert_equal('', @renderer.result)
    @renderer.push("something")
    assert_equal('something', @renderer.result)
    @renderer.push(["completely", "different"])
    assert_equal('somethingcompletelydifferent', @renderer.result)
  end

  def test_unshift
    assert_equal('', @renderer.result)
    @renderer.unshift("something")
    assert_equal('something', @renderer.result)
    @renderer.unshift(["completely", "different"])
    assert_equal('completelydifferentsomething', @renderer.result)
  end

  def test_render
    assert_equal('', @renderer.result)
    assert_equal('something', @renderer.render('something'))
    assert_equal('', @renderer.result)
  end

  def test_result
    assert(false, 'Need to write test_result tests')
  end
end

class TestCompositeRenderer < Test::Unit::TestCase
  def test_addRenderer
    assert(false, 'Need to write test_addRenderer tests')
  end

  def test_render
    assert(false, 'Need to write test_render tests')
  end
end

class TestHtmlRenderer < ZenTest

  def set_up
    super
    @renderer = HtmlRenderer.new(@doc)
  end

  def test_array2html_one_level
    assert_equal("<UL>\n  <LI>line 1</LI>\n  <LI>line 2</LI>\n</UL>\n",
		 @renderer.array2html(["line 1", "line 2"]))
  end

  def test_array2html_multi_level

    assert_equal("<UL>\n  <LI>line 1</LI>\n  <UL>\n    <LI>line 1.1</LI>\n    <LI>line 1.2</LI>\n  </UL>\n  <LI>line 2</LI>\n  <UL>\n    <LI>line 2.1</LI>\n    <UL>\n      <LI>line 2.1.1</LI>\n    </UL>\n  </UL>\n</UL>\n",
		 @renderer.array2html([ "line 1", 
					[ "line 1.1", "line 1.2" ], 
					"line 2", 
					[ "line 2.1",
					  [ "line 2.1.1" ] ] ]))
  end

  def test_hash2html
    assert_equal("<DL>\n  <DT>key1</DT>\n  <DD>val1</DD>\n\n  <DT>key2</DT>\n  <DD>val2</DD>\n\n  <DT>key3</DT>\n  <DD>val3</DD>\n\n</DL>\n",
		 @renderer.hash2html({ 'key1' => 'val1',
				       'key2' => 'val2',
				       'key3' => 'val3' }))
  end

  def test_render
    assert(false, 'Need to write test_render tests')
  end

end

class TestHtmlTemplateRenderer < ZenTest

  def test_render_html_and_head

    assert_not_nil(@content.index("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">
<HTML>
<HEAD>
<TITLE>Ryan\'s Homepage: Version 2.0</TITLE>
<LINK REV=\"MADE\" HREF=\"mailto:ryand-web@zenspider.com\">
<META NAME=\"rating\" CONTENT=\"general\">
<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">
<META NAME=\"author\" CONTENT=\"Ryan Davis\">
<META NAME=\"copyright\" CONTENT=\"1996-2001, Zen Spider Software\">
</HEAD>
<BODY>
<P>
<A HREF=\"../SiteMap.html\"><STRONG>Sitemap</STRONG></A> || <A HREF=\"../index.html\">My Website</A>
 / Ryan\'s Homepage</P>
<H1>Ryan\'s Homepage</H1>
<H2>Version 2.0</H2>
<HR SIZE=\"3\" NOSHADE>"),
		   "Must render the HTML header and all appropriate metadata")
  end

  def test_render_foot
    @content = @doc.renderContent
    expected = "\n<HR SIZE=\"3\" NOSHADE>\n\n<P>\n<A HREF=\"../SiteMap.html\"><STRONG>Sitemap</STRONG></A> || <A HREF=\"../index.html\">My Website</A>\n / Ryan's Homepage</P>\n\n<P>This is my footer, jive turkey</P></BODY>\n</HTML>\n"

    assert_not_nil(@content.index(expected),
		   "Must render the HTML footer")
  end

  def test_navbar
    @content = @doc.renderContent
    assert(@content =~ "<A HREF=\"../SiteMap.html\"><STRONG>Sitemap</STRONG></A> || <A HREF=\"../index.html\">My Website</A>\n / Ryan\'s Homepage</P>\n",
	   "Must render navbar correctly")
  end

end

class TestSubpageRenderer < ZenTest

  def set_up
    super
    @renderer = SubpageRenderer.new(@doc)
  end

  def test_render

    result = @renderer.render('')

    assert_equal([ "\n\n",
		   "** Subpages:\n\n",
		   "+ <A HREF=\"/~ryand/blah.html\">blah</A>\n",
		   "+ <A HREF=\"/~ryand/stuff/index.html\">my stuff</A>\n",
		   "\n" ].join(''),
		 result)
  end

end

class TestTextToHtmlRenderer < ZenTest

  def util_render(regex, msg)
    # FIX: just render from the renderer directly
    @content = @doc.renderContent
    assert(@content =~ regex, msg)
  end

  def test_render_headers
    util_render(%r,<H2>Head 2</H2>,,
		       "Must render H2 from **")

    util_render(%r,<H3>Head 3</H3>,,
		       "Must render H3 from ***")

    util_render(%r,<H4>Head 4</H4>,,
		       "Must render H4 from ****")

    util_render(%r,<H5>Head 5</H5>,,
		       "Must render H5 from *****")

    util_render(%r,<H6>Head 6</H6>,,
		       "Must render H6 from ******")

  end

  def test_render_list1

    # TODO: test like this:
    # r = TextToHtmlRenderer.new(@doc)
    # result = r.render("+ blah1\n+ blah2")

    util_render(%r%<UL>\n  <LI>Lists \(should have two items\).</LI>\n  <LI>Continuted Lists.</LI>\n</UL>%,
		       "Must render normal list from +")
  end

  def test_render_list2
    util_render(%r%<UL>\n  <LI>Another List \(should have a sub list\).</LI>\n  <UL>\n    <LI>With a sub-list</LI>\n    <LI>another item</LI>\n  </UL>\n</UL>%,
		       "Must render compound list from indented +'s")
  end

  def test_render_dict1
    util_render("<DL>\n  <DT>Term 1</DT>\n  <DD>Def 1</DD>\n\n  <DT>Term 2</DT>\n  <DD>Def 2</DD>\n\n</DL>\n\n",
		       "Must render simple dictionary list")
  end

  def test_render_metadata
    util_render(%r,Glossary lookups for 42 and some string \(see metadata.txt for a hint\)\.\s+key99 should not look up\.,,
		       "Must render metadata lookups from \#\{key\}")
  end

  def test_render_metadata_eval
    r = MetadataRenderer.new(@doc)
    result = r.render("blah #\{1+1\} blah")
    assert_equal("blah 2 blah", result,
		 "MetadataRenderer must evaluate ruby expressions")
  end

  def test_render_small_rule
    util_render(%r,^<HR SIZE="1" NOSHADE>$,,
		       "Must render small rule from ---")
  end

  def test_render_big_rule
    util_render(%r,^<HR SIZE="2" NOSHADE>$,,
		       "Must render big rule from ===")
  end

  def test_render_paragraph1
    util_render(%r,^<P>Paragraphs can contain <A HREF="http://www\.ZenSpider\.com/ZSS/ZenWeb/">www\.ZenSpider\.com /ZSS /ZenWeb</A> and <A HREF="mailto:zss@ZenSpider\.com">zss@ZenSpider\.com</A> and they will automatically be converted\..*?</P>$,,
		       "Must render paragraph from a single line")
  end

  def test_render_paragraph2
    util_render(%r;^<P>Likewise, two lines side by side\s+are considered one paragraph\..*?</P>$;,
		       "Must render paragraph from multiple lines")
  end

  def test_render_paragraph3
    util_render(%r@Don\'t forget less-than "&lt;" &amp; greater-than "&gt;", but only if backslashed.</P>$@,
		       "Must convert special entities")
  end

  def test_render_paragraph4
    util_render(%r;Supports <I>Embedded HTML</I>\.</P>$;,
		       "Must render paragraph from multiple lines")
  end

  def test_render_paragraph5
    util_render(%r;Supports <A HREF=\"http://www.yahoo.com\">Unaltered urls</A> as well\.</P>$;,
		       "Must render full urls without conversion")
  end

  def test_render_pre

    util_render("<PRE>PRE blocks are paragraphs that are indented two spaces on each line.\nThe two spaces will be stripped, and all other indentation will be left\nalone.\n   this allows me to put things like code examples in and retain\n       their formatting.</PRE>",
		       "Must render PRE blocks from indented paragraphs")
  end

  def test_createList_flat
    r = TextToHtmlRenderer.new(@doc)

    assert_equal(["line 1", "line 2"],
		 r.createList("line 1\nline 2\n"))
  end

  def test_createList_deep
    r = TextToHtmlRenderer.new(@doc)

    assert_equal([ "line 1", 
		   [ "line 1.1", "line 1.2" ], 
		   "line 2", 
		   [ "line 2.1",
		     [ "line 2.1.1" ] ] ],
		 r.createList("line 1\n\tline 1.1\n\tline 1.2\n" +
			      "line 2\n\tline 2.1\n\t\tline 2.1.1"))
  end

  def test_createHash_simple
    r = TextToHtmlRenderer.new(@doc)

    assert_equal({"term 1" => "def 1", "term 2" => "def 2"},
		 r.createHash("%- term 1\n%= def 1\n%-term 2\n%=def 2"))
  end
end

class TestFooterRenderer < ZenTest
  def test_render
    # must create own web so we do not attach to a pregenerated index.html
    web = ZenWebsite.new(@sitemapUrl, "test", "testhtml")
    @doc = ZenDocument.new("/index.html", web)

    @doc['footer'] = "footer 1\n";
    @doc['renderers'] = [ 'FooterRenderer' ]

    # TODO: need to test content w/ close HTML tag
    @doc.content = "line 1\nline 2\nline 3\n"

    content = @doc.renderContent

    assert_equal("line 1\nline 2\nline 3\nfooter 1\n", content)
  end
end

class TestHeaderRenderer < ZenTest
  def test_render
    @doc = ZenDocument.new("/index.html", @web)
    @doc['header'] = "header 1\n";
    @doc['renderers'] = [ 'HeaderRenderer' ]
    @doc.content = "line 1\nline 2\nline 3\n"

    content = @doc.renderContent

    assert_equal("header 1\nline 1\nline 2\nline 3\n", content)
  end
end

class TestMetadataRenderer < Test::Unit::TestCase
  def test_render
    assert(false, 'Need to write test_render tests')
  end
end

class TestSitemapRenderer < ZenTest

  def set_up
    super
  end

  def test_render_normal
    @doc = @web.sitemap
    @content = @doc.content
    @renderer = SitemapRenderer.new(@doc)

    result = @renderer.render(@content)

    expected = [
      "+ <A HREF=\"/index.html\">My Website: Subtitle</A>\n",
      "+ <A HREF=\"/SiteMap.html\">Sitemap: There are 6 pages in this website.</A>\n", 
      "+ <A HREF=\"/Something.html\">Something</A>\n",
      "+ <A HREF=\"/~ryand/index.html\">Ryan's Homepage: Version 2.0</A>\n",
      "\t+ <A HREF=\"/~ryand/blah.html\">blah</A>\n",
      "\t+ <A HREF=\"/~ryand/stuff/index.html\">my stuff</A>\n"
    ].join('')

    assert_equal(expected, result, "Must properly convert the urls to a list")
  end

  def test_render_subsite
    # this is a weird one... if my sitemap is something like:
    #   /~ryand/index.html
    #   /~ryand/SiteMap.html
    # then ZenWeb somehow thinks that sitemap is a subdirectory to index.

    @web = ZenWebsite.new('/~ryand/SiteMap.html', "test", "testhtml")
    @doc = @web['/~ryand/SiteMap.html']
    @content = @doc.content
    @renderer = SitemapRenderer.new(@doc)

    result = @renderer.render(@content)

    expected = [
      "+ <A HREF=\"/~ryand/index.html\">Ryan's Homepage: Version 2.0</A>\n",
      "+ <A HREF=\"/~ryand/SiteMap.html\">Sitemap: There are 4 pages in this website.</A>\n",
      "+ <A HREF=\"/~ryand/blah.html\">blah</A>\n",
      "+ <A HREF=\"/~ryand/stuff/index.html\">my stuff</A>\n"
    ].join('')

    # FIX: need a sub-sub-page to test indention at that level

    assert_equal(expected, result, "Must properly convert the urls to a list")
  end

end

class TestRelativeRenderer < ZenTest
  def set_up
    super
    @renderer = RelativeRenderer.new(@doc)
  end

  def test_render

    content = [
      '<A HREF="http://www.yahoo.com/blah/blah.html">stuff</A>',
      '<a href="/something.html">something</A>',
      '<a href="/subdir/">other dir</A>',
      '<a href="/~ryand/blah.html">same dir</A>'
    ].join('')

    expect  = [
      '<A HREF="http://www.yahoo.com/blah/blah.html">stuff</A>',
      '<a href="../something.html">something</A>',
      '<a href="../subdir/">other dir</A>',
      '<a href="blah.html">same dir</A>'
    ].join('')

    result = @renderer.render(content)

    # just to satisfy me and make sure the relative urls are still there...
    @doc.render

    assert_equal(expect, result)
  end

  def test_convert

    assert_equal('http://www.yahoo.com/blah/blah.html',
		 @renderer.convert('http://www.yahoo.com/blah/blah.html'))

    assert_equal('../something.html',
		 @renderer.convert('/something.html'))

    assert_equal('../subdir/',
		 @renderer.convert('/subdir/'))

    assert_equal('blah.html',
		 @renderer.convert('/~ryand/blah.html'))
  end
end

class TestRubyCodeRenderer < Test::Unit::TestCase
  def test_render
    assert(false, 'Need to write test_render tests')
  end
end

class TestTocRenderer < ZenTest

  def set_up
    super
  end

  def test_render

    @renderer = TocRenderer.new(@doc)

    content = [
      "This is some content, probably the intro...\n",
      "\n",
      "** Section 1\n",
      "\n",
      "This is more content 1\n",
      "\n",
      "*** Section 1.1\n",
      "\n",
      "This is more content 2\n",
      "\n",
      "** Section 2:\n",
      "\n",
      "This is more content 3\n",
      "\n",
    ].join('')

    expected = [

      "** <A NAME=\"0\">Contents:</A>\n",
      "\n",
      "+ <A HREF=\"#0\">Contents</A>\n",
      "+ <A HREF=\"#1\">Section 1</A>\n",
      "\t+ <A HREF=\"#2\">Section 1.1</A>\n",
      "+ <A HREF=\"#3\">Section 2</A>\n",

      "This is some content, probably the intro...\n",
      "\n",
      "** <A NAME=\"1\">Section 1</A>\n",
      "\n",
      "This is more content 1\n",
      "\n",
      "*** <A NAME=\"2\">Section 1.1</A>\n",
      "\n",
      "This is more content 2\n",
      "\n",
      "** <A NAME=\"3\">Section 2</A>\n", # note the lack of colon at the end
      "\n",
      "This is more content 3\n",
      "\n",
    ].join('')

    result = @renderer.render(content)

    assert_equal(expected, result, "Must properly generate TOC")
  end
end

# this is more here to shut up ZenTest than anything else.
class TestXXXRenderer < Test::Unit::TestCase
  def test_render
    assert(false, 'Need to write test_render tests')
  end
end

class TestStupidRenderer < Test::Unit::TestCase
  def test_leet
    assert(false, 'Need to write test_leet tests')
  end

  def test_render
    assert(false, 'Need to write test_render tests')
  end

  def test_strip
    assert(false, 'Need to write test_strip tests')
  end
end


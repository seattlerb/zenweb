#!/usr/local/bin/ruby -w

$TESTING = TRUE

require 'ZenWeb'
require 'ZenWeb/SitemapRenderer'
require 'ZenWeb/TocRenderer'
require 'ZenWeb/StupidRenderer'

require 'test/unit'

# this is used across different classes for html list tests
$text_list_data = "+ a\n\t+ a1\n\t\t+ a1a\n+ b\n\t+ b1\n\t\t+ b1a\n\t\t+ b1b\n+ c\n\t+ c1\n\t\t+ c1a\n\t+ c2\n\t\t+ c2a\n\t\t+ c2b\n\t\t+ c2c\n\t\t+ c2d"
$array_list_data = ['a', ['a1', ['a1a']], 'b', ['b1', ['b1a', 'b1b' ]], 'c', ['c1', ['c1a'], 'c2', ['c2a', 'c2b', 'c2c', 'c2d']]]
$html_list_data = "<UL>\n<LI>a</LI>\n<UL>\n<LI>a1</LI>\n<UL>\n<LI>a1a</LI>\n</UL>\n</UL>\n<LI>b</LI>\n<UL>\n<LI>b1</LI>\n<UL>\n<LI>b1a</LI>\n<LI>b1b</LI>\n</UL>\n</UL>\n<LI>c</LI>\n<UL>\n<LI>c1</LI>\n<UL>\n<LI>c1a</LI>\n</UL>\n<LI>c2</LI>\n<UL>\n<LI>c2a</LI>\n<LI>c2b</LI>\n<LI>c2c</LI>\n<LI>c2d</LI>\n</UL>\n</UL>\n</UL>\n"

class String
  def uberstrip
    (self.split($/).map {|x| x.strip}).join($/)
  end
end

def shutupwhile
  $dead = File.open("/dev/null", "w")

  $stdout.flush
  $stderr.flush

  oldstdout = $stdout
  oldstderr = $stderr

  $stdout = $dead
  $stderr = $dead

  yield

  $stdout.flush
  $stderr.flush

  $stdout = oldstdout
  $stderr = oldstderr
end

class ZenTestCase < Test::Unit::TestCase # ZenTest SKIP

  def setup
    @datadir = "test"
    @htmldir = "testhtml"
    @sitemapUrl = "/SiteMap.html"
    @url = "/~ryand/index.html"
    @web = ZenWebsite.new(@sitemapUrl, @datadir, @htmldir)
    @doc = @web[@url]
    @content = @doc.renderContent
  end

  def test_null
    # shuts up test::unit's stupid logic
  end

  def teardown
    if (test(?d, @htmldir)) then
      `rm -rf #{@htmldir}` 
    end
  end

end

############################################################
# ZenWebsite:

class TestZenWebsite < ZenTestCase

  def teardown
    if (test(?d, @htmldir)) then
      `rm -rf #{@htmldir}`
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
    datadir = @web.datadir
    assert(datadir.instance_of?(String),
	   "ZenWebsite's htmldir must be instantiated")
    assert(test(?d, datadir),
	   "ZenWebsite's datadir must be a directory")
  end

  # WARN: I think these tests are too prescriptive
  # REFACTOR: make an OrderedHash
  def test_doc_order
    doc_order = @web.doc_order
    assert_kind_of(Array, doc_order)
    assert(doc_order.size > 0, "doc_order better not be empty")
  end

  def test_documents
    documents = @web.documents
    assert_kind_of(Hash, documents)
    assert(documents.size > 0, "Documents better not be empty")
    assert_not_nil(documents["/SiteMap.html"], "SiteMap must exist")
  end

  def test_htmldir
    htmldir = @web.htmldir
    assert_not_nil(htmldir, "htmldir must be initialized")
    assert_instance_of(String, htmldir)
  end

  def test_sitemap
    sitemap = @web.sitemap
    assert(sitemap.instance_of?(ZenSitemap),
	   "ZenWebsite's Sitemap must be instantiated")
  end

end

############################################################
# ZenDocument

class TestZenDocument < ZenTestCase

  def setup
    super
    @expected_datapath = "test/ryand/index"
    @expected_htmlpath = "testhtml/ryand/index.html"
    @expected_dir = "test/ryand"
    @expected_subpages = [ '/~ryand/blah.html', '/~ryand/stuff/index.html' ]
  end

  def test_initialize_good_url
    assert_nothing_raised {
      ZenDocument.new("/Something.html", @web)
    }
  end

  def test_initialize_missing_ext
    assert_nothing_raised {
      ZenDocument.new("/Something", @web)
    }
  end

  def test_initialize_missing_slash
    assert_raises(ArgumentError) {
      ZenDocument.new("Something.html", @web)
    }
  end

  def test_initialize_bad_url
    assert_raises(ArgumentError) {
      ZenDocument.new("/missing.html", @web)
    }
  end

  def test_initialize_nil_website
    assert_raises(ArgumentError) {
      ZenDocument.new("Something.html", nil)
    }
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

    assert_raises(NotImplementedError,
		  "renderContent must throw a NotImplementedError") {
      @doc.renderContent
    }
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

    time_old = '01010000'
    time_new = '01020000'

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

  def test_addSubpage_bad
    assert_raises(ArgumentError, "addSubpage must raise if arg wrong type") {
      @doc.addSubpage []
    }
    assert_raises(ArgumentError, "subpage must be a url, not a page") {
      @doc.addSubpage @doc
    }
  end

  def test_addSubpage_different
    oldpages = @doc.subpages.clone
    url = "/Something.html"
    @doc.addSubpage(url)
    newpages = @doc.subpages
    assert(newpages.size == oldpages.size + 1,
	   "Page must grow the list of subpages")
    found = newpages.find {|p| p == url }
    assert_not_nil(found, "Page must be contained in new list")
  end

  def test_addSubpage_same
    oldpages = @doc.subpages.clone
    url = @url
    @doc.addSubpage(url)
    newpages = @doc.subpages
    assert(newpages.size == oldpages.size,
	   "Page must NOT grow the list of subpages")
    found = newpages.find {|p| p == url }
    assert_nil(found, "Page must be contained in new list")
  end

  def test_content
    content = @doc.content
    assert_not_nil(content, "Content must not be nil")
    assert_instance_of(String, content)
  end

  def test_content=()
    orig_content = @doc.content
    @doc.content = "blah"
    new_content = @doc.content
    assert_not_nil(new_content, "Content must not be nil")
    assert_instance_of(String, new_content)
    assert_equal("blah", new_content)
  end

  def test_datadir # same as TestZenWebsite#test_datadir since it's a delegate
    datadir = @web.datadir
    assert(datadir.instance_of?(String),
	   "ZenWebsite's htmldir must be instantiated")
    assert(test(?d, datadir),
	   "ZenWebsite's datadir must be a directory")
  end

  def test_fulltitle
    @doc['title'] = "Title"
    @doc['subtitle'] = "Subtitle"
    assert_equal("Title: Subtitle", @doc.fulltitle)
  end

  def test_htmldir # same as TestZenWebsite#test_htmldir since it's a delegate
    htmldir = @doc.htmldir
    assert_not_nil(htmldir, "htmldir must be initialized")
    assert_instance_of(String, htmldir)
  end

  def test_index
    result = @doc["renderers"]
    assert_not_nil(result, "renderers must exist for document")
    assert_instance_of(Array, result)
  end

  def test_index_equals
    newrenderers = ["Something"]
    @doc["renderers"] = newrenderers
    metadata = @doc.metadata
    assert_not_nil(metadata, "metadata must not be nil")
    assert_instance_of(Metadata, metadata)
    result = metadata["renderers"]
    assert_not_nil(result, "renderers must exist in sitemap")
    assert_instance_of(Array, result)
    assert_not_nil(result.find {|x| x == "Something"})
  end

  def test_metadata
    metadata = @doc.metadata
    assert_not_nil(metadata, "metadata must not be nil")
    assert_instance_of(Metadata, metadata)
    result = metadata["renderers"]
    assert_not_nil(result, "renderers must exist in sitemap")
    assert_instance_of(Array, result)
  end

  def test_parseMetadata
    @doc = ZenDocument.new('/index.html', @web)

    # metadata should be nil at this point.
    # content should be an empty string
    # as soon as we ask for metadata, it should
    # parse... /index.html has 'key4' defined in
    # it.

    assert_equal('', @doc.content)
    assert_not_nil(@doc.metadata, 'metadata should always be non-nil')
    assert(@doc.content.length > 0, 'file should be parsed now')
    assert_equal(69, @doc['key4'])
  end

  def test_url
    url = @doc.url
    assert_not_nil(url, "Each document must know it's url")
    assert_kind_of(String, url)
    assert_equal(@url, url)
  end

  def test_website
    website = @doc.website
    assert_not_nil(website, "Each document must know of it's website")
    assert_kind_of(ZenWebsite, website)
  end
end

############################################################
# ZenSitemap

class TestZenSitemap < TestZenDocument

  def setup
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

class TestMetadata < ZenTestCase

  def setup
    @hash = Metadata.new("test/ryand")
  end

  def teardown
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

class ZenRendererTest < ZenTestCase

  def setup
    super

    if self.class.name =~ /Test(\w+Renderer)$/ then
      rendererclass = $1
      require "ZenWeb/#{rendererclass}"
      theClass = Module.const_get(rendererclass)
      @renderer = theClass.send("new", @doc) # TODO: move everyone over to this
    end

  end
end

class TestGenericRenderer < ZenRendererTest

  def setup
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
    @renderer.push('this is some text')
    assert_equal('this is some text', @renderer.result)
  end
end

class TestCompositeRenderer < ZenRendererTest
  def test_renderers
    newrenderer = StupidRenderer.new(@doc)
    assert_equal([], @renderer.renderers)
    @renderer.addRenderer(newrenderer)
    assert_equal([newrenderer], @renderer.renderers)
  end

  def test_addRenderer
    renderer = CompositeRenderer.new(@doc)
    originalRenderers = renderer.renderers.clone
    assert_raises(ArgumentError, "Must throw an ArgumentError if passed non-renderer") {
      renderer.addRenderer([])
    }
    assert_raises(ArgumentError, "Must throw an ArgumentError if passed nil") {
      renderer.addRenderer(nil)
    }

    newRenderer = FooterRenderer.new(@doc)
    renderer.addRenderer(newRenderer)
    newRenderers = renderer.renderers

    assert(originalRenderers.size + 1 == newRenderers.size,
	   "Renderer addition must have grown array")
    assert_equal(newRenderer, newRenderers.last,
		"Renderer must be in array")
  end

  def test_render_empty
    text = "this is some text"
    assert_equal(text, @renderer.render(text))
  end

  def test_render_one
    @doc['stupidmethod'] = 'strip'
    @renderer.addRenderer(StupidRenderer.new(@doc))
    text = "this is some text"
    assert_equal('ths s sm txt', @renderer.render(text))
  end

  def test_render_many
    @doc['stupidmethod'] = 'strip'
    @doc['footer'] = 'footer'
    @renderer.addRenderer(StupidRenderer.new(@doc))
    @renderer.addRenderer(FooterRenderer.new(@doc))
    text = "this is some text"
    assert_equal('ths s sm txtfooter', @renderer.render(text))
  end
end

class TestStandardRenderer < ZenRendererTest
  def test_initialize
    renderers = @renderer.renderers
    assert_equal(5, renderers.size)
    assert_instance_of(SubpageRenderer, renderers[0])
    assert_instance_of(MetadataRenderer, renderers[1])
    assert_instance_of(TextToHtmlRenderer, renderers[2])
    assert_instance_of(HtmlTemplateRenderer, renderers[3])
    assert_instance_of(FooterRenderer, renderers[4])
  end
end

class TestHtmlRenderer < ZenRendererTest

  def test_array2html_one_level
    assert_equal("<UL>\n  <LI>line 1</LI>\n  <LI>line 2</LI>\n</UL>\n",
		 @renderer.array2html(["line 1", "line 2"]))
  end

  def test_array2html_multi_level
    assert_equal($html_list_data.uberstrip,
		 @renderer.array2html($array_list_data).uberstrip)
  end

  def test_hash2html
    assert_equal("<DL>\n  <DT>key3</DT>\n  <DD>val3</DD>\n\n  <DT>key2</DT>\n  <DD>val2</DD>\n\n  <DT>key1</DT>\n  <DD>val1</DD>\n\n</DL>\n",
		 @renderer.hash2html({ 'key3' => 'val3',
				       'key2' => 'val2',
				       'key1' => 'val1' },
				     [ 'key3', 'key2', 'key1' ]))
  end

  def test_render
    assert_raises(RuntimeError, "should raise a subclass responsibity error") {
      @renderer.render("anything")
    }
  end

end

class TestHtmlTemplateRenderer < ZenRendererTest

  # TODO: need to test the following: html element conversions, url
  # conversions, headers, rules, pre blocks, paragraphs

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
<P class=\"navbar\">
<A HREF=\"../SiteMap.html\">Sitemap</A> || <A HREF=\"../index.html\">My Website</A>
 / Ryan\'s Homepage</P>
<H1>Ryan\'s Homepage</H1>
<H2>Version 2.0</H2>
<HR SIZE=\"3\" NOSHADE>"),
		   "Must render the HTML header and all appropriate metadata")
  end

  def test_render_foot
    @content = @doc.renderContent
    expected = "\n<HR SIZE=\"3\" NOSHADE>\n\n<P class=\"navbar\">\n<A HREF=\"../SiteMap.html\">Sitemap</A> || <A HREF=\"../index.html\">My Website</A>\n / Ryan's Homepage</P>\n\n<P>This is my footer, jive turkey</P></BODY>\n</HTML>\n"

    assert_not_nil(@content.index(expected),
		   "Must render the HTML footer")
  end

  def test_navbar
    @content = @doc.renderContent
    assert(@content =~ %r%<A HREF=\"../SiteMap.html\">Sitemap</A> || <A HREF=\"../index.html\">My Website</A>\n / Ryan\'s Homepage</P>\n%,
	   "Must render navbar correctly")
  end

end

class TestSubpageRenderer < ZenRendererTest

  def setup
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

class TestTextToHtmlRenderer < ZenRendererTest

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
    util_render(%r%<DL>\n  <DT>Term 1</DT>\n  <DD>Def 1</DD>\n\n  <DT>Term 2</DT>\n  <DD>Def 2</DD>\n\n</DL>\n\n%,
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

    util_render(%r%<PRE>PRE blocks are paragraphs that are indented two spaces on each line.\nThe two spaces will be stripped, and all other indentation will be left\nalone.\n   this allows me to put things like code examples in and retain\n       their formatting.</PRE>%,
		       "Must render PRE blocks from indented paragraphs")
  end

  def test_createList_flat
    r = TextToHtmlRenderer.new(@doc)

    assert_equal(["line 1", "line 2"],
		 r.createList("line 1\nline 2\n"))
  end

  def test_createList_deep
    r = TextToHtmlRenderer.new(@doc)

    assert_equal($array_list_data, r.createList($text_list_data),
		 "createList must create the correct array from the text")
  end

  def test_createHash_simple
    r = TextToHtmlRenderer.new(@doc)
    hash, order = r.createHash("%- term 2\n%= def 2\n%-term 1\n%=def 1")

    assert_equal({"term 2" => "def 2", "term 1" => "def 1"}, hash)
    assert_equal(["term 2", "term 1"], order)
  end
end

class TestFooterRenderer < ZenRendererTest
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

class TestHeaderRenderer < ZenRendererTest
  def test_render
    @doc = ZenDocument.new("/index.html", @web)
    @doc['header'] = "header 1\n";
    @doc['renderers'] = [ 'HeaderRenderer' ]
    @doc.content = "line 1\nline 2\nline 3\n"

    content = @doc.renderContent

    assert_equal("header 1\nline 1\nline 2\nline 3\n", content)
  end
end

class TestMetadataRenderer < ZenRendererTest
  def test_render
    @doc['nothing'] = 'you'
    assert_equal('I hate you', @renderer.render('I hate #{nothing}'))
  end

  def test_include
    r = MetadataRenderer.new(@doc)
    result = r.render("TEXT\n\#{include '../include.txt'}\nTEXT")
    expected = "TEXT\n#metadata = false\nThis is some 42\ncommon text.\nTEXT"
    assert_equal(expected, result,
		 "Include should inject text from files")
  end

  def test_include_strip
    r = MetadataRenderer.new(@doc)
    result = r.render("TEXT\n\#{include '../include.txt', true}\nTEXT")
    expected = "TEXT\nThis is some 42\ncommon text.\nTEXT"
    assert_equal(expected, result,
		 "Include should inject text from files")
  end

  def test_link
    r = MetadataRenderer.new(@doc)
    result = r.render("TEXT\n\#{link '/index.html', 'Go Away'}\nTEXT")
    expected = "TEXT\n<A HREF=\"/index.html\">Go Away</A>\nTEXT"
    assert_equal(expected, result,
		 "link should create appropriate href")
  end

  def test_img
    r = MetadataRenderer.new(@doc)
    result = r.render("TEXT\n\#{img '/goaway.png', 'Go Away'}\nTEXT")
    expected = "TEXT\n<IMG SRC=\"/goaway.png\" ALT=\"Go Away\" BORDER=0>\nTEXT"
    assert_equal(expected, result,
		 "img should create appropriate img")
  end

end

class TestSitemapRenderer < ZenRendererTest

  def setup
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

class TestRelativeRenderer < ZenRendererTest

  def setup
    super
    @renderer = RelativeRenderer.new(@doc)
  end

  def test_render

    content = [
      '<A HREF="http://www.yahoo.com/blah/blah.html">stuff</A>',
      '<a href="/something.html">something</A>',
      '<a href="/subdir/">other dir</A>',
      '<a href="/~ryand/blah.html">same dir</A>',
      '<a href="#location">same page</A>',
      '<A HREF="http://www.yahoo.com/blah/blah.html#location">stuff</A>',
      '<a href="/something.html#location">something</A>',
      '<a href="/subdir/#location">other dir</A>',
      '<a href="/~ryand/blah.html#location">same dir</A>',
    ].join('')

    expect  = [
      '<A HREF="http://www.yahoo.com/blah/blah.html">stuff</A>',
      '<a href="../something.html">something</A>',
      '<a href="../subdir/">other dir</A>',
      '<a href="blah.html">same dir</A>',
      '<a href="#location">same page</A>',
      '<A HREF="http://www.yahoo.com/blah/blah.html#location">stuff</A>',
      '<a href="../something.html#location">something</A>',
      '<a href="../subdir/#location">other dir</A>',
      '<a href="blah.html#location">same dir</A>',
    ].join('')

    result = @renderer.render(content)

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

class TestRubyCodeRenderer < ZenRendererTest
  def test_render()
    # XMP is a POS, so this is as much as I'm willing to test right
    # now until I can pinpoint the bug and go though xmp properly or
    # bypass it altogether...

    shutupwhile {
      assert_match(/<EM>4<\/EM>/, @renderer.render("! 2+2"))
    }
  end
end

class TestTocRenderer < ZenRendererTest

  def setup
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

class TestStupidRenderer < ZenRendererTest
  def util_render(input, expected)
    result = @renderer.render(input)
    assert_equal(expected, result)
  end

  def test_render_undefined
    util_render("This is some text", "This is some text")
  end

  def test_render_leet
    @doc['stupidmethod'] = 'leet'
    util_render("This is some text", '+]-[|$ |$ $0/\/\3 +3><+')
  end

  def test_render_strip
    @doc['stupidmethod'] = 'strip'
    util_render("This is some text", "Ths s sm txt")
  end

  def test_render_unknown
    @doc['stupidmethod'] = 'dunno'
    assert_raises(NameError) {
      @renderer.render("anything")
    }
  end

  def test_leet
    result = @renderer.leet("This is some text")
    assert_equal('+]-[|$ |$ $0/\/\3 +3><+', result)
  end

  def test_strip
    result = @renderer.strip("This is some text")
    assert_equal("Ths s sm txt", result)
  end
end

class TestCompactRenderer < ZenRendererTest
  def test_render

    input = "
<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML//EN\">
<html>
  <head>
    <title>Title</title>
  </head>
  <body>

    <h1>Title</h1>

    <p>blah blah</p>
    <pre>line 1
line 2
line 3</pre>

  </body>
</html>
"

    expected = "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML//EN\"><html><head><title>Title</title></head><body><h1>Title</h1><p>blah blah</p><pre>line 1
line 2
line 3</pre></body></html>"

    assert_equal(expected, @renderer.render(input))
  end
end

class TestHtmlTableRenderer < ZenRendererTest
  def test_render_plain
    input = "<tabs>
a\tb\tc
d\te\tf
</tabs>
"

    expected = "<table border=\"0\">
<tr><th>a</th><th>b</th><th>c</th></tr>
<tr><td>d</td><td>e</td><td>f</td></tr>
</table>

"

    assert_equal(expected, @renderer.render(input))
  end

  def test_render_multitabs
    input = "<tabs>
a\tb\t\t\tc
d\t\t\te\tf
</tabs>
"

    expected = "<table border=\"0\">
<tr><th>a</th><th>b</th><th>c</th></tr>
<tr><td>d</td><td>e</td><td>f</td></tr>
</table>

"

    assert_equal(expected, @renderer.render(input))
  end


  def test_render_paragraphs
    input = "something

<tabs>
a\tb\t\t\tc
d\t\t\te\tf
</tabs>

something else
"

    expected = "something

<table border=\"0\">
<tr><th>a</th><th>b</th><th>c</th></tr>
<tr><td>d</td><td>e</td><td>f</td></tr>
</table>

something else


"

    assert_equal(expected, @renderer.render(input))
  end
end

# this is more here to shut up ZenTest than anything else.
class TestXXXRenderer < ZenRendererTest
  def test_render
    assert_equal("This is a test", @renderer.render("This is a test"))
  end
end

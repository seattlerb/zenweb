#!/usr/local/bin/ruby -w

$TESTING = TRUE

require 'ZenWeb'
require 'ZenWeb/SitemapRenderer'
require 'ZenWeb/TocRenderer'
require 'ZenWeb/StupidRenderer'

require 'test/unit/testcase'

# TODO: get rid of all calls to renderContent

# this is used across different classes for html list tests
$text_list_data = "+ a\n\t+ a1\n\t\t+ a1a\n+ b\n\t+ b1\n\t\t+ b1a\n\t\t+ b1b\n+ c\n\t+ c1\n\t\t+ c1a\n\t+ c2\n\t\t+ c2a\n\t\t+ c2b\n\t\t+ c2c\n\t\t+ c2d"
$array_list_data = ['a', ['a1', ['a1a']], 'b', ['b1', ['b1a', 'b1b' ]], 'c', ['c1', ['c1a'], 'c2', ['c2a', 'c2b', 'c2c', 'c2d']]]
$html_list_data = "<UL>\n<LI>a\n<UL>\n<LI>a1\n<UL>\n<LI>a1a</LI>\n</UL>\n</LI>\n</UL>\n</LI>\n<LI>b\n<UL>\n<LI>b1\n<UL>\n<LI>b1a</LI>\n<LI>b1b</LI>\n</UL>\n</LI>\n</UL>\n</LI>\n<LI>c\n<UL>\n<LI>c1\n<UL>\n<LI>c1a</LI>\n</UL>\n</LI>\n<LI>c2\n<UL>\n<LI>c2a</LI>\n<LI>c2b</LI>\n<LI>c2c</LI>\n<LI>c2d</LI>\n</UL>\n</LI>\n</UL>\n</LI>\n</UL>\n"

class String
  def uberstrip
    (self.split($/).map {|x| x.strip}).join($/)
  end
end

def shutupwhile_18
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

def shutupwhile_16
  $dead = File.open("/dev/null", "w")

  $stdout.flush
  $stderr.flush
  $defout.flush

  oldstdout = $stdout.dup
  oldstderr = $stderr.dup

  $stdout.reopen($dead)
  $stderr.reopen($dead)
  $defout.reopen($dead)

  yield

  $stdout.flush
  $stderr.flush
  $defout.flush

  $stdout = oldstdout
  $stderr = oldstderr
  $defout.reopen($stdout)
end

if RUBY_VERSION.sub(/(\d+)\.(\d+).*/, '\1\2').to_i <= 16 then
  alias :shutupwhile :shutupwhile_16
else
  alias :shutupwhile :shutupwhile_18
end

class ZenTestCase < Test::Unit::TestCase # ZenTest SKIP

  def setup
    $stderr.puts name if $DEBUG
    @datadir = "test"
    @htmldir = "testhtml"
    @sitemapUrl = "/SiteMap.html"
    @url = "/~ryand/index.html"
    @web = ZenWebsite.new(@sitemapUrl, @datadir, @htmldir)
    @doc = @web[@url]
  end

  def teardown
    if (test(?d, @htmldir)) then
      `rm -rf #{@htmldir}` 
    end
  end

  def test_null
    # shuts up test::unit's stupid logic
  end
end

############################################################
# ZenWebsite:

class TestZenWebsite < ZenTestCase

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
#    expected = "<H2>There are 6 pages in this website.</H2>\n<HR CLASS=\"thick\">\n\n<UL>\n  <LI><A HREF=\"/index.html\">My Website: Subtitle</A></LI>\n  <LI><A HREF=\"/SiteMap.html\">Sitemap: There are 6 pages in this website.</A></LI>\n  <LI><A HREF=\"/Something.html\">Something</A></LI>\n  <LI><A HREF=\"/~ryand/index.html\">Ryan's Homepage: Version 2.0</A></LI>\n  <UL>\n    <LI><A HREF=\"/~ryand/blah.html\">blah</A></LI>\n    <LI><A HREF=\"/~ryand/stuff/index.html\">my stuff</A></LI>\n  </UL>\n</UL>"
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
      @renderer = theClass.new(@doc)
    end
  end

  def util_render(expected, input, message="")
    assert_equal(expected, @renderer.render(input), message)
  end
end

class TestGenericRenderer < ZenRendererTest

  def test_push
    assert_equal('', @renderer.result)
    @renderer.push("something")
    assert_equal('something', @renderer.result(false))
    @renderer.push(["completely", "different"])
    assert_equal('somethingcompletelydifferent', @renderer.result)
  end

  def test_unshift
    assert_equal('', @renderer.result)
    @renderer.unshift("something")
    assert_equal('something', @renderer.result(false))
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

  def util_scan_region(expected, input, &block)
    @renderer.scan_region(input, /<start>/, /<end>/, &block)
    assert_equal expected, @renderer.result
  end

  def test_scan_region_miss
    s = "this is some text\n"
    util_scan_region(s, s) do |region, context|
      flunk "There is no region"
    end
  end

  def test_scan_region_one_line
    s = 'text <start>region<end> text'

    util_scan_region('', s) do |region, context|
      assert_equal s, region, "Region must match entire line"
    end
  end

  def test_scan_region_single
    s = "text\n<start>\nregion\n<end>\ntext"
    e = "text\nfound\ntext"
    util_scan_region(e, s) do |region, context|
      @renderer.push "found\n" unless context == :START or context == :END
    end
  end

  def ztest_scan_region_multiple
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
    @content = @doc.renderContent # HACK!!! Quells NameError: uninitialized constant TestCompositeRenderer::FooterRenderer (no idea how)
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
    # TODO: AAAAAAHHHHHHHH!
    assert_instance_of(SubpageRenderer, renderers[0])
    assert_instance_of(MetadataRenderer, renderers[1])
    assert_instance_of(TextToHtmlRenderer, renderers[2])
    assert_instance_of(HtmlTemplateRenderer, renderers[3])
    assert_instance_of(FooterRenderer, renderers[4])
  end
end

class TestFileAttachmentRenderer < ZenRendererTest

  def setup
    super
    path = @doc.htmlpath
    dir = File.dirname(path)
    
    unless (test(?d, dir)) then
      File::makedirs(dir)
    end
  end

  # TODO: push this as far up as possible
  def test_nothing
    s = "blah blah\n\nblah blah\n\nblah blah\n\nblah blah"
    util_render s, s, "FAR must not modify text that doesn't contain file tags"
  end

  # TODO: refactor
  def test_simple
    f = "line 1\nline 2\nline 3\n"
    f2 = "  line 1\n  line 2\n  line 3"
    s = "blah blah\n\n<file name=\"something.txt\">\n#{f}</file>\n\nblah blah"
    e = "blah blah\n\n#{f2}\n\n<A HREF=\"something.txt\">Download something.txt</A>\n\nblah blah"
    util_render e, s, "FAR must render the content correctly"
    assert test(?f, 'testhtml/ryand/something.txt'), "File must exist or you suck"
    assert_equal f, File.new('testhtml/ryand/something.txt').read
  end

  def test_eric_is_a_fucktard
    f = "line 1\n\nline 2\nline 3\n"
    f2 = "  line 1\n  \n  line 2\n  line 3"
    s = "blah blah\n\n<file name=\"something.txt\">\n#{f}</file>\n\nblah blah"
    e = "blah blah\n\n#{f2}\n\n<A HREF=\"something.txt\">Download something.txt</A>\n\nblah blah"
    util_render e, s, "FAR must render the content correctly, even if eric is a fucktard"
    assert test(?f, 'testhtml/ryand/something.txt'), "File must exist or you suck"
    assert_equal f, File.new('testhtml/ryand/something.txt').read
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

  def test_array2html_one_level_ordered
    assert_equal("<OL>\n  <LI>line 1</LI>\n  <LI>line 2</LI>\n</OL>\n",
		 @renderer.array2html(["line 1", "line 2"], true))
  end

  def test_array2html_multi_level_ordered
    assert_equal($html_list_data.gsub("UL", "OL").uberstrip,
		 @renderer.array2html($array_list_data, true).uberstrip)
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
    @content = @doc.renderContent
    assert_not_nil(@content.index("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">
<HTML>
<HEAD>
<TITLE>Ryan\'s Homepage: Version 2.0</TITLE>
<LINK REV=\"MADE\" HREF=\"mailto:ryand-web@zenspider.com\">
<META NAME=\"rating\" CONTENT=\"general\">
<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">
<META NAME=\"author\" CONTENT=\"Ryan Davis\">
<META NAME=\"copyright\" CONTENT=\"1996-2001, Zen Spider Software\">
<link rel=\"up\" href=\"../index.html\" title=\"My Website\">
<link rel=\"contents\" href=\"../SiteMap.html\" title=\"Sitemap\">
<link rel=\"top\" href=\"../index.html\" title=\"My Website\">
</HEAD>
<BODY>
<P class=\"navbar\">
<A HREF=\"../SiteMap.html\">Sitemap</A> || <A HREF=\"../index.html\">My Website</A>
 / Ryan\'s Homepage</P>
<H1>Ryan\'s Homepage</H1>
<H2>Version 2.0</H2>
<HR CLASS=\"thick\""),
		   "Must render the HTML header and all appropriate metadata")
  end

  def test_render_foot
    @content = @doc.renderContent
    expected = "\n<HR CLASS=\"thick\">\n\n<P class=\"navbar\">\n<A HREF=\"../SiteMap.html\">Sitemap</A> || <A HREF=\"../index.html\">My Website</A>\n / Ryan's Homepage</P>\n\n<P>This is my footer, jive turkey</P></BODY>\n</HTML>\n"

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

  def test_render_table
    util_render("<table><tr><td>\n\n<P>blah</P>\n\n</td></tr></table>\n\n",
                "%%\n\nblah\n\n%%",
                "unadorned div sections should render")
  end

  def test_render_table_with_div
    util_render("<table><tr><td>\n\n<div class=\"blah1\"><div>\n\n<P>blah</P>\n\n</div></div>\n</td></tr></table>\n\n",
                "%%\n\n%%% class=\"blah1\"\n\nblah\n\n%%",
                "unadorned div sections should render")
  end

  def test_render_table_with_2_divs
    util_render("<table><tr><td>\n\n<div class=\"blah1\"><div>\n\n<P>blah1</P>\n\n</div></div>\n</td><td>\n<div class=\"blah2\"><div>\n\n<P>blah2</P>\n\n</div></div>\n</td></tr></table>\n\n",
                "%%\n\n%%% class=\"blah1\"\n\nblah1\n\n%%% class=\"blah2\"\n\nblah2\n\n%%",
                "unadorned div sections should render")
  end

  def test_render_div
    util_render("<div class=\"blah\"><div>\n\n<P>blah</P>\n\n</div></div>\n\n",
                "%%% class=\"blah\"\n\nblah\n\n%%%",
                "styled div sections should render")
  end

  def test_render_headers
    util_render("<H2>Head 2</H2>\n\n", "** Head 2",
                "Must render H2 from **")

    util_render("<H3>Head 3</H3>\n\n", "*** Head 3",
                "Must render H3 from ***")

    util_render("<H4>Head 4</H4>\n\n", "**** Head 4",
                "Must render H4 from ****")

    util_render("<H5>Head 5</H5>\n\n", "***** Head 5",
                "Must render H5 from *****")

    util_render("<H6>Head 6</H6>\n\n", "****** Head 6",
                "Must render H6 from ******")

  end

  def test_render_ul1

    # TODO: test like this:
    # r = TextToHtmlRenderer.new(@doc)
    # result = r.render("+ blah1\n+ blah2")

    util_render("<UL>\n  <LI>Lists (should have two items).</LI>\n  <LI>Continuted Lists.</LI>\n</UL>\n",
                 "+ Lists (should have two items).\n+ Continuted Lists.\n",
                 "Must render normal list from +")
  end

  def test_render_ul2
    util_render("<UL>\n  <LI>Another List \(should have a sub list\).\n    <UL>\n      <LI>With a sub-list</LI>\n      <LI>another item</LI>\n    </UL>\n  </LI>\n</UL>\n",
                 "+ Another List (should have a sub list).\n\t+ With a sub-list\n\t+ another item\n",
		       "Must render compound list from indented +'s")
  end

  def test_render_ol1
    util_render("<OL>\n  <LI>Ordered lists</LI>\n  <LI>are cool\n    <OL>\n      <LI>Especially when you make ordered sublists</LI>\n    </OL>\n  </LI>\n</OL>\n", "= Ordered lists\n= are cool\n\t= Especially when you make ordered sublists\n",
                 "Must render compound list from indented ='s")
  end

  def test_render_dict1
    util_render("<DL>\n  <DT>Term 1</DT>\n  <DD>Def 1</DD>\n\n  <DT>Term 2</DT>\n  <DD>Def 2</DD>\n\n</DL>\n\n",
                "%- Term 1\n%= Def 1\n%- Term 2\n%= Def 2",
                "Must render simple dictionary list")
  end

  def test_render_metadata_eval
    r = MetadataRenderer.new(@doc)
    result = r.render("blah #\{1+1\} blah")
    assert_equal("blah 2 blah", result,
		 "MetadataRenderer must evaluate ruby expressions")
  end

  def test_render_rule_small
    util_render("<HR>\n\n", "---",
                 "Must render small rule from ---")
  end

  def test_render_rule_big
    util_render(%Q(<HR CLASS="thick">\n\n), "===",
		       "Must render big rule from ===")
  end

  def test_render_paragraph
    util_render("<P>Paragraphs can contain <A HREF=\"http://www.ZenSpider.com/ZSS/ZenWeb/\">www.ZenSpider.com /ZSS /ZenWeb</A> and <A HREF=\"mailto:zss@ZenSpider.com\">zss@ZenSpider.com</A> and they will automatically be converted. Don't forget less-than \"&lt;\" &amp; greater-than \"&gt;\", but only if backslashed.</P>\n\n",
                "Paragraphs can contain http://www.ZenSpider.com/ZSS/ZenWeb/ and mailto:zss@ZenSpider.com and they will automatically be converted. Don't forget less-than \"\\<\" \\& greater-than \"\\>\", but only if backslashed.\n",
		       "Must render paragraph from a single line")
  end

  def test_render_paragraph_2_lines_and_embedded
    util_render("<P>Likewise, two lines side by side\nare considered one paragraph. Supports <I>Embedded HTML</I>.</P>\n\n",
                "Likewise, two lines side by side\nare considered one paragraph. Supports <I>Embedded HTML</I>.
",
                "Must render paragraph from multiple lines")
  end

  def test_render_paragraph_urls
    util_render(%Q%<P>Supports <A HREF=\"http://www.yahoo.com\">Unaltered urls</A> as well\.</P>\n\n%,
                %Q%Supports <A HREF="http://www.yahoo.com">Unaltered urls</A> as well.%,
                "Must render full urls without conversion")
  end

  def test_render_paragraph_tag_normal
    util_render("<P>blah</P>\n\n", "blah")
  end

  def test_render_paragraph_tag_div
    util_render("<DIV>blah</DIV>\n\n", "<DIV>blah</DIV>")
  end

  def test_render_paragraph_tag_p
    util_render("<P>blah</P>\n\n", "<P>blah</P>")
  end

  def test_render_paragraph_tag_unknown
    util_render("<P><XXX>blah</XXX></P>\n\n", "<XXX>blah</XXX>")
  end

  def test_render_paragraph_tag_h1
    util_render("<H1>blah</H1>\n\n", "<H1>blah</H1>")
  end

  def test_render_pre
    util_render("<PRE>PRE blocks are paragraphs that are indented two spaces on each line.\nThe two spaces will be stripped, and all other indentation will be left\nalone.\n   this allows me to put things like code examples in and retain\n       their formatting.</PRE>\n\n",
                "  PRE blocks are paragraphs that are indented two spaces on each line.\n  The two spaces will be stripped, and all other indentation will be left\n  alone.\n     this allows me to put things like code examples in and retain\n         their formatting.\n",
                "Must render PRE blocks from indented paragraphs")
  end

  def test_createList_flat
    assert_equal(["line 1", "line 2"],
		 @renderer.createList("line 1\nline 2\n"))
  end

  def test_createList_deep
    assert_equal($array_list_data,
                 @renderer.createList($text_list_data),
		 "createList must create the correct array from the text")
  end

  def test_createHash_simple
    hash, order = @renderer.createHash("%- term 2\n%= def 2\n%-term 1\n%=def 1")

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
    util_render 'I hate you', 'I hate #{nothing}', 'metadata must be accessed from @doc'
  end

  def test_include
    util_render "TEXT\n#metadata = false\nThis is some 42\ncommon text.\nTEXT",
                "TEXT\n\#{include '../include.txt'}\nTEXT",
		"Include should inject text from files"
  end

  def test_unknown
    @doc["key1"] = 42
    @doc["key2"] = "some string"

    util_render("Glossary lookups for 42 and some string but key99 should not look up.",
                "Glossary lookups for #\{key1} and #\{key2} but #\{key99} should not look up.",
                "Must render metadata lookups from \#\{key\}")
  end



  def test_include_strip
    util_render("TEXT\nThis is some 42\ncommon text.\nTEXT", 
                "TEXT\n\#{include '../include.txt', true}\nTEXT",
                "Include should inject text from files")
  end

  def test_link
    util_render("TEXT\n<A HREF=\"/index.html\">Go Away</A>\nTEXT",
                "TEXT\n\#{link '/index.html', 'Go Away'}\nTEXT",
                "link should create appropriate href")
  end

  def test_img
    util_render("TEXT\n<IMG SRC=\"/goaway.png\" ALT=\"Go Away\">\nTEXT",
                "TEXT\n\#{img '/goaway.png', 'Go Away'}\nTEXT",
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
      result = @renderer.render("! 2+2")
      assert_equal ">> 2+2\n=><EM> 4</EM>\n", result
    }
  end
end

class TestTocRenderer < ZenRendererTest

  def test_render

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

class TestCalendarRenderer < ZenRendererTest
  def setup
    super
    @oct = "<table class=\"calendar\"><tr><td valign=\"top\"><table class=\"view y2004 m10\">
<tr class=\"title\">
<th colspan=7>October 2004</th>
</tr>
<tr class=\"weektitle\"
<th class=\"sun\">Sun</th>
<th class=\"mon\">Mon</th>
<th class=\"tue\">Tue</th>
<th class=\"wed\">Wed</th>
<th class=\"thu\">Thu</th>
<th class=\"fri\">Fri</th>
<th class=\"sat\">Sat</th></tr>
<tr class=\"days firstweek\">
<td colspan=5>&nbsp;</td>
<td class=\"d01 fri\">1</td>
<td class=\"d02 sat\">2</td>
</tr>
<tr class=\"days\">
<td class=\"d03 sun\">3</td>
<td class=\"d04 mon\">4</td>
<td class=\"d05 tue\">5</td>
<td class=\"d06 wed\">6</td>
<td class=\"d07 thu\">7</td>
<td class=\"d08 fri\">8</td>
<td class=\"d09 sat\">9</td>
</tr>
<tr class=\"days\">
<td class=\"d10 sun\">10</td>
<td class=\"d11 mon\">11</td>
<td class=\"d12 tue\">12</td>
<td class=\"d13 wed\">13</td>
<td class=\"d14 thu\">14</td>
<td class=\"d15 fri\">15</td>
<td class=\"d16 sat\">16</td>
</tr>
<tr class=\"days\">
<td class=\"d17 sun\">17</td>
<td class=\"d18 mon\">18</td>
<td class=\"d19 tue\">19</td>
<td class=\"d20 wed\">20</td>
<td class=\"d21 thu\">21</td>
<td class=\"d22 fri\">22</td>
<td class=\"d23 sat\">23</td>
</tr>
<tr class=\"days\">
<td class=\"d24 sun\">24</td>
<td class=\"d25 mon\">25</td>
<td class=\"d26 tue\">26</td>
<td class=\"d27 wed event\">27</td>
<td class=\"d28 thu\">28</td>
<td class=\"d29 fri\">29</td>
<td class=\"d30 sat\">30</td>
</tr>
<tr class=\"days\">
<td class=\"d31 sun\">31</td>
<td colspan=6>&nbsp;</td>
</tr>
</table>
</td>
<td class=\"eventlist\">
<ul>
<li>2004-10-27:
<ul>
<li>Ryan's birfday!
</ul>
</ul>
</td>
</tr>
</table>
"

    @may = "<table class=\"calendar\"><tr><td valign=\"top\"><table class=\"view y2004 m05\">
<tr class=\"title\">
<th colspan=7>May 2004</th>
</tr>
<tr class=\"weektitle\"
<th class=\"sun\">Sun</th>
<th class=\"mon\">Mon</th>
<th class=\"tue\">Tue</th>
<th class=\"wed\">Wed</th>
<th class=\"thu\">Thu</th>
<th class=\"fri\">Fri</th>
<th class=\"sat\">Sat</th></tr>
<tr class=\"days firstweek\">
<td colspan=6>&nbsp;</td>
<td class=\"d01 sat\">1</td>
</tr>
<tr class=\"days\">
<td class=\"d02 sun\">2</td>
<td class=\"d03 mon\">3</td>
<td class=\"d04 tue\">4</td>
<td class=\"d05 wed\">5</td>
<td class=\"d06 thu\">6</td>
<td class=\"d07 fri\">7</td>
<td class=\"d08 sat\">8</td>
</tr>
<tr class=\"days\">
<td class=\"d09 sun\">9</td>
<td class=\"d10 mon\">10</td>
<td class=\"d11 tue\">11</td>
<td class=\"d12 wed\">12</td>
<td class=\"d13 thu\">13</td>
<td class=\"d14 fri\">14</td>
<td class=\"d15 sat\">15</td>
</tr>
<tr class=\"days\">
<td class=\"d16 sun\">16</td>
<td class=\"d17 mon\">17</td>
<td class=\"d18 tue\">18</td>
<td class=\"d19 wed\">19</td>
<td class=\"d20 thu\">20</td>
<td class=\"d21 fri\">21</td>
<td class=\"d22 sat\">22</td>
</tr>
<tr class=\"days\">
<td class=\"d23 sun\">23</td>
<td class=\"d24 mon\">24</td>
<td class=\"d25 tue\">25</td>
<td class=\"d26 wed event\">26</td>
<td class=\"d27 thu\">27</td>
<td class=\"d28 fri\">28</td>
<td class=\"d29 sat\">29</td>
</tr>
<tr class=\"days\">
<td class=\"d30 sun\">30</td>
<td class=\"d31 mon\">31</td>
<td colspan=5>&nbsp;</td>
</tr>
</table>
</td>
<td class=\"eventlist\">
<ul>
<li>2004-05-26:
<ul>
<li>Eric's bifday!
</ul>
</ul>
</td>
</tr>
</table>
"
  end

  def test_render_forward
    expect = @may + @oct
    input  = "<cal>
2004-05-26: Eric's bifday!
2004-10-27: Ryan's birfday!
</cal>"
    util_render(expect, input)
  end

  def test_render_empty_last_week
    expect = "<table class=\"calendar\"><tr><td valign=\"top\"><table class=\"view y2004 m07\">\n<tr class=\"title\">\n<th colspan=7>July 2004</th>\n</tr>\n<tr class=\"weektitle\"\n<th class=\"sun\">Sun</th>\n<th class=\"mon\">Mon</th>\n<th class=\"tue\">Tue</th>\n<th class=\"wed\">Wed</th>\n<th class=\"thu\">Thu</th>\n<th class=\"fri\">Fri</th>\n<th class=\"sat\">Sat</th></tr>\n<tr class=\"days firstweek\">\n<td colspan=4>&nbsp;</td>\n<td class=\"d01 thu event\">1</td>\n<td class=\"d02 fri\">2</td>\n<td class=\"d03 sat\">3</td>\n</tr>\n<tr class=\"days\">\n<td class=\"d04 sun\">4</td>\n<td class=\"d05 mon\">5</td>\n<td class=\"d06 tue\">6</td>\n<td class=\"d07 wed\">7</td>\n<td class=\"d08 thu\">8</td>\n<td class=\"d09 fri\">9</td>\n<td class=\"d10 sat\">10</td>\n</tr>\n<tr class=\"days\">\n<td class=\"d11 sun\">11</td>\n<td class=\"d12 mon\">12</td>\n<td class=\"d13 tue\">13</td>\n<td class=\"d14 wed\">14</td>\n<td class=\"d15 thu\">15</td>\n<td class=\"d16 fri\">16</td>\n<td class=\"d17 sat\">17</td>\n</tr>\n<tr class=\"days\">\n<td class=\"d18 sun\">18</td>\n<td class=\"d19 mon\">19</td>\n<td class=\"d20 tue\">20</td>\n<td class=\"d21 wed\">21</td>\n<td class=\"d22 thu\">22</td>\n<td class=\"d23 fri\">23</td>\n<td class=\"d24 sat\">24</td>\n</tr>\n<tr class=\"days\">\n<td class=\"d25 sun\">25</td>\n<td class=\"d26 mon\">26</td>\n<td class=\"d27 tue\">27</td>\n<td class=\"d28 wed\">28</td>\n<td class=\"d29 thu\">29</td>\n<td class=\"d30 fri\">30</td>\n<td class=\"d31 sat\">31</td>\n</tr>\n</table>\n</td>\n<td class=\"eventlist\">\n<ul>\n<li>2004-07-01:\n<ul>\n<li>blah\n</ul>\n</ul>\n</td>\n</tr>\n</table>\n"
    input  = "<cal>
2004-07-01: blah
</cal>"
    util_render(expect, input)
  end

  def test_render_reverse
    expect = @oct + @may
    input  = "<cal reverse>
2004-05-26: Eric's bifday!
2004-10-27: Ryan's birfday!
</cal>"
    util_render(expect, input)
  end
end

class TestStupidRenderer < ZenRendererTest
  def test_render_undefined
    util_render("This is some text", "This is some text")
  end

  def test_render_leet
    @doc['stupidmethod'] = 'leet'
    util_render('+]-[|$ |$ $0/\/\3 +3><+', "This is some text")
  end

  def test_render_strip
    @doc['stupidmethod'] = 'strip'
    util_render("Ths s sm txt", "This is some text")
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

require 'test/unit' if $0 == __FILE__

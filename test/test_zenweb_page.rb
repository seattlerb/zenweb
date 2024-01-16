#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPage < Minitest::Test
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def setup_deps
    Rake.application = Rake::Application.new
    site.scan

    assert_empty Rake.application.tasks.map(&:name) - ["virtual_pages"]

    p1 = site.pages["blog/2012-01-02-page1.html.md"]
    p2 = site.pages["blog/2012-01-03-page2.html.md"]

    return p1, p2
  end

  def setup_complex_website2 skip_monthly = false
    self.site = Zenweb::Site.new

    pages = %w[
      index.html.md
      ruby/index.html.md
      ruby/notes.html.md
      ruby/quickref.html.md
      blog/2014/index.html.md
      blog/2014/01/index.html.md
      blog/2014-01-01-first.html.md
      blog/2014/02/index.html.md
      blog/2014-02-02-second.html.md
      blog/2014/03/index.html.md
      blog/2014-03-03-third.html.md
      blog/index.html.md
    ]

    pages.reject! { |s| s =~ /blog.2.*index/ } if skip_monthly

    build_fake_site(*pages)

    site.pages["index.html.md"]
  end

  def test_all_subpages
    top = setup_complex_website2
    sp  = site.pages
    exp = [[sp["blog/index.html.md"],
            [[sp["blog/2014/index.html.md"],
              [[sp["blog/2014/01/index.html.md"],
                [[sp["blog/2014-01-01-first.html.md"], []]]],
               [sp["blog/2014/02/index.html.md"],
                [[sp["blog/2014-02-02-second.html.md"], []]]],
               [sp["blog/2014/03/index.html.md"],
                [[sp["blog/2014-03-03-third.html.md"], []]]]]]]],
           [sp["ruby/index.html.md"],
            [[sp["ruby/notes.html.md"], []],
             [sp["ruby/quickref.html.md"], []]]]]

    assert_equal exp, top.all_subpages
  end

  make_my_diffs_pretty!

  def test_all_subpages_reversed
    top = setup_complex_website2
    sp  = site.pages

    exp = [[sp["blog/index.html.md"],
            [[sp["blog/2014/index.html.md"],
              [[sp["blog/2014/03/index.html.md"],
                [[sp["blog/2014-03-03-third.html.md"], []]]],
               [sp["blog/2014/02/index.html.md"],
                [[sp["blog/2014-02-02-second.html.md"], []]]],
               [sp["blog/2014/01/index.html.md"],
                [[sp["blog/2014-01-01-first.html.md"], []]]]]]]],
           [sp["ruby/index.html.md"],
            [[sp["ruby/notes.html.md"], []],
             [sp["ruby/quickref.html.md"], []]]]]

    assert_equal exp, top.all_subpages(true)
  end

  def test_all_subpages_complex_reversed
    top = setup_complex_website2
    sp = site.pages

    exp = [[sp["blog/index.html.md"],
            [[sp["blog/2014/index.html.md"],
              [[sp["blog/2014/03/index.html.md"],
                [[sp["blog/2014-03-03-third.html.md"], []]]],
               [sp["blog/2014/02/index.html.md"],
                [[sp["blog/2014-02-02-second.html.md"], []]]],
               [sp["blog/2014/01/index.html.md"],
                [[sp["blog/2014-01-01-first.html.md"], []]]]]]]],
           [sp["ruby/index.html.md"],
            [[sp["ruby/notes.html.md"], []],
             [sp["ruby/quickref.html.md"], []]]]]
    assert_equal exp, top.all_subpages(true)
  end

  def test_sitemap_complex_no_dates # TODO: move to markdown tests
    top = setup_complex_website2

    exp = "* [Title for blog/index.html.md](/blog/)
  * [Title for blog/2014/index.html.md](/blog/2014/)
    * [Title for blog/2014/03/index.html.md](/blog/2014/03/)
      * [Title for blog/2014-03-03-third.html.md](/blog/2014/03/03/third.html)
    * [Title for blog/2014/02/index.html.md](/blog/2014/02/)
      * [Title for blog/2014-02-02-second.html.md](/blog/2014/02/02/second.html)
    * [Title for blog/2014/01/index.html.md](/blog/2014/01/)
      * [Title for blog/2014-01-01-first.html.md](/blog/2014/01/01/first.html)
* [Title for ruby/index.html.md](/ruby/)
  * [Title for ruby/notes.html.md](/ruby/notes.html)
  * [Title for ruby/quickref.html.md](/ruby/quickref.html)"

    assert_equal exp, top.sitemap(false)
  end

  def test_sitemap_title_dated_no_monthlies # TODO: move to markdown tests
    top = setup_complex_website2 :skip_monthly

    exp = "* [Title for blog/index.html.md](/blog/)
  * 2014-03:
    * [Title for blog/2014-03-03-third.html.md](/blog/2014/03/03/third.html)
  * 2014-02:
    * [Title for blog/2014-02-02-second.html.md](/blog/2014/02/02/second.html)
  * 2014-01:
    * [Title for blog/2014-01-01-first.html.md](/blog/2014/01/01/first.html)
* [Title for ruby/index.html.md](/ruby/)
  * [Title for ruby/notes.html.md](/ruby/notes.html)
  * [Title for ruby/quickref.html.md](/ruby/quickref.html)"

    assert_equal exp, top.sitemap(:title_dated)
  end

  def test_binary
    page = Zenweb::Page.new site, "blah"
    refute_predicate page, :binary?

    page = Zenweb::Page.new site, "blah", site.config
    assert_predicate page, :binary?
  end

  def test_body
    assert_equal "Not really much here to see.", page.body
  end

  def test_breadcrumbs
    site.scan
    self.page = site.pages[page.path]

    exp = %w[/index.html /blog/index.html]

    assert_equal exp, page.breadcrumbs.map(&:url)
  end

  def test_clean_url
    act = page.clean_url
    exp = "/blog/2012/01/02/page1.html"

    assert_equal exp, act

    page = Zenweb::Page.new site, "a/b/index.html"
    act = page.clean_url
    exp = "/a/b/"

    assert_equal exp, act
  end

  def test_config
    exp = {"title" => "Example Page 1"}

    assert_kind_of Zenweb::Config, page.config
    assert_equal exp, page.config.h
  end

  def test_content
    assert_equal File.read(page.path), page.content
  end

  def test_date
    assert_equal Time.local(2012, 1, 2), page.date
  end

  def test_date_from_path
    assert_equal Time.local(2012, 1, 2), page.date_from_path
  end

  def test_depends_on
    p1, p2 = setup_deps

    p1.depends_on p2

    assert_tasks do
      assert_task "virtual_pages", nil, Rake::Task
      assert_task p1.url_path, [p2.url_path]
    end
  end

  def test_depends_on_string
    p1, _ = setup_deps

    p1.depends_on "somethingelse"

    # TODO: double check that this should be p1.path and not p1.url_path
    assert_tasks do
      assert_task "virtual_pages", nil, Rake::Task
      assert_task p1.path, ["somethingelse"]
    end
  end

  def test_filetype
    assert_equal "md", page.filetype
  end

  def test_filetypes
    assert_equal %w[md], page.filetypes
  end

  def test_filetypes_odd
    page = Zenweb::Page.new site, "blah.wtf"
    assert_equal %w[], page.filetypes
  end

  def test_generate
    page = Zenweb::Page.new site, "blah"

    def page.render
      "woot"
    end

    def page.open path, mode
      yield $stdout
    end

    out = "woot\n"
    err = "Rendering .site/blah\n"

    assert_output out, err do
      page.generate
    end
  end

  def test_generate_binary
    page = Zenweb::Page.new site, "blah", site.config

    def page.render
      "woot"
    end

    def page.open path, mode
      yield $stdout
    end

    out = "woot"
    err = "Rendering .site/blah\n"

    assert_output out, err do
      page.generate
    end
  end

  def test_generate_via_invoke
    Rake.application = Rake::Application.new
    site.scan
    site.wire
    self.page = site.pages["blog/2012-01-02-page1.html.md"]
    Rake.application[page.url_path].clear_prerequisites # no mkdir, thanks

    def page.generate
      raise "no generate"
    end

    e = assert_raises RuntimeError do
      Rake.application[page.url_path].invoke
    end

    assert_equal "no generate", e.message
  ensure
    FileUtils.rm_rf ".site"
  end

  def test_html_eh
    assert page.html?

    site.scan
    refute site.pages["js/site.js"].html?
  end

  def test_include
    # test via a layout page so we can test indirect access of page vars
    layout = Zenweb::Page.new(site, "_layouts/site.erb")
    fragment = layout.include("header.html.erb", page)
    assert_match(/Example Page 1/, fragment)
  end

  def test_include_page_var
    # test via a layout page so we can test indirect access of page vars
    layout = Zenweb::Page.new(site, "_layouts/site.erb")
    fragment = layout.include("header.html.erb", page)
    assert_match "Example Page 1 ~ Example Website", fragment
  end

  def test_index
    assert_equal page.config["title"], page["title"]
  end

  def test_index_missing
    exp = "/blog/2012/01/02/page1.html does not define \"missing\"\n"

    assert_output "", exp do
      assert_nil page["missing"]
    end
  end

  def test_inspect
    assert_equal 'Page["blog/2012-01-02-page1.html.md"]', page.inspect
  end

  def test_layout
    site.scan # to load layouts

    assert_equal site.layout("post"), page.layout
  end

  def test_link_html
    exp = "<a href=\"/blog/2012/01/02/page1.html\">Example Page 1</a>"
    assert_equal exp, page.link_html

    exp = "<a href=\"/blog/2012/01/02/page1.html\">blah</a>"
    assert_equal exp, page.link_html("blah")
  end

  def test_meta
    exp = '<meta name="title" content="Example Page 1">'
    assert_equal exp, page.meta("title")
  end

  def test_method_missing
    assert_equal page["title"], page.method_missing("title")
  end

  def test_method_missing_odd
    e = assert_raises NoMethodError do
      assert_nil page.method_missing("wtf")
    end

    assert_includes e.message, "undefined method `wtf'"
  end

  def test_method_missing_render
    e = assert_raises NoMethodError do
      assert_nil page.render_wtf
    end

    assert_match(/undefined method `render_wtf' for.*?Zenweb::Page/,  e.message)
  end

  def test_layout_nil_string
    e = assert_raises RuntimeError do
      page.config.h["layout"] = "nil"
      page.layout
    end

    exp = 'unknown layout "nil" for page "blog/2012-01-02-page1.html.md"'
    assert_equal exp, e.message
  end

  def test_parent
    site.scan
    self.page = site.pages[page.path]

    assert_equal site.pages["blog/index.html.erb"], page.parent
  end

  def test_parent_top
    build_fake_site %w[index.html]

    page = site.pages["index.html"]

    assert_nil page.parent
  end

  def test_parent_url
    assert_equal "/blog/2012/01/02/page1.html", page.url
    assert_equal "/blog/2012/01/02/index.html", page.parent_url

    page = Zenweb::Page.new(site, "a/b/c.html")
    assert_equal "/a/b/index.html", page.parent_url

    page = Zenweb::Page.new(site, "a/b/index.html")
    assert_equal "/a/index.html", page.parent_url
  end

  def test_path
    assert_equal "blog/2012-01-02-page1.html.md", page.path
  end

  def test_render
    page.instance_variable_set :@layout, nil # keep it skinny
    assert_equal "<p>Not really much here to see.</p>\n", page.render
  end

  def test_render_image
    self.page = Zenweb::Page.new site, "img/bg.png"
    assert_equal File.binread("img/bg.png"), page.render
  end

  def test_run_js_script
    exp = <<-EOM.gsub(/^ {6}/, '')
      <script type=\"text/javascript\">
        (function() {
          var s   = document.createElement('script');
          s.type  = 'text/javascript';
          s.async = true;
          s.src   = 'my_url';
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(s);
        })();
      </script>
    EOM

    assert_equal exp, page.run_js_script("my_url")
  end

  def test_site
    assert_equal site, page.site
  end

  def test_stylesheet
    exp = %(<link rel="stylesheet" type="text/css" href="/css/woot.css" />)
    assert_equal exp, page.stylesheet("woot")
  end

  def test_subpages
    site.scan

    page = site.pages["blog/index.html.erb"]
    act = page.subpages
    exp = [site.pages["blog/2012-01-02-page1.html.md"],
           site.pages["blog/2012-01-03-page2.html.md"],
           site.pages["blog/2012-01-04-page3.html.md"]]

    assert_equal exp, act
  end

  def test_subpages_subdirs
    build_fake_site %w[index.html
                       a/index.html
                       a/a.html
                       a/b.html
                       a/c.html
                       b/index.html
                       b/2012-01-02-p1.html
                       b/2012-01-03-p2.html
                       b/2012-01-04-p3.html
                       c/index.html
                       c/a.html
                       c/b.html
                       c/c.html
                       c/d/e.html
                       c/d/f.html
                       c/d/g.html
                       d/index.html
                       d/2012-01-02-p1.html
                       d/2012-01-03-p2.html
                       d/2012-01-04-p3.html
                       some_random_page.html
                      ]

    urls = %w[a/index.html
              b/index.html
              c/index.html
              d/index.html
              some_random_page.html]

    exp = urls.map { |url| site.pages[url] }

    page = site.pages["index.html"]
    assert_equal exp, page.subpages
  end

  def test_subrender
    assert_equal "<p>Not really much here to see.</p>\n", page.subrender
  end

  def test_to_s
    assert_equal 'Page["blog/2012-01-02-page1.html.md"]', page.to_s
  end

  def test_url
    assert_equal "/blog/2012/01/02/page1.html", page.url
  end

  def test_url_date_fmt
    page.config.h["date_fmt"] = "%Y/%m"
    assert_equal "/blog/2012/01/page1.html", page.url
  end

  def test_url_regular_page
    page = Zenweb::Page.new site, "pages/blah.html"
    assert_equal "/pages/blah.html", page.url
  end

  def test_url_dir
    assert_equal ".site/blog/2012/01/02", page.url_dir
  end

  def test_url_path
    assert_equal ".site/blog/2012/01/02/page1.html", page.url_path
  end

  def test_wire
    Rake.application = Rake::Application.new
    site.scan
    self.page = site.pages["blog/2012-01-02-page1.html.md"]

    page.wire

    assert_tasks do
      assert_task "virtual_pages", nil, Rake::Task

      # dirs
      assert_task ".site"
      assert_task ".site/blog"
      assert_task ".site/blog/2012"
      assert_task ".site/blog/2012/01"
      assert_task ".site/blog/2012/01/02"

      # aux
      assert_task "_layouts/post.erb", %w[_config.yml _layouts/site.erb]
      assert_task "_layouts/site.erb", %w[_config.yml]
      assert_task "blog/_config.yml", %w[_config.yml]
      assert_task "_config.yml"

      # page down to site
      assert_task page.path, %w[_layouts/post.erb blog/_config.yml]
      assert_task page.url_path, [page.url_dir, page.path]
      assert_task "site", [page.url_path], Rake::Task
    end
  end
end

class TestGenerated < Minitest::Test
  include ChdirTest("example-site")

  class MonthlyTest < Zenweb::MonthlyPage
    def content
      "woot"
    end
  end

  class YearlyTest < Zenweb::YearlyPage
    def content
      "woot"
    end
  end

  attr_accessor :site

  def assert_date klass, *args
    setup_complex_website

    path = "blog/2014/01/index.html"
    pages = []
    monthly = klass.new(site, path, pages, *args)

    exp_date = Time.local 2014, 1

    assert_equal exp_date, monthly.date
    assert_equal exp_date, monthly["date"]

  end

  def test_monthly_date
    assert_date MonthlyTest, 2014, 1
  end

  def test_yearly_date
    assert_date YearlyTest, 2014
  end
end

#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

require 'pry'

class TestZenwebPageMarkdown < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page, :plugin

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
    self.plugin = Zenweb::MarkdownPlugin.new
    self.plugin.underlying_page = page
  end

  def test_attr_h
    assert_equal "{:blah=\"42\"}", plugin.attr("blah" => 42)
  end

  def test_attr_name
    assert_equal "{:blah}", plugin.attr("blah")
  end

  def test_css_class
    assert_equal "{:.blah}", plugin.css_class("blah")
  end

  def test_css_id
    assert_equal "{:#blah}", plugin.css_id("blah")
  end

  def test_link
    assert_equal "[mytitle](myurl)", plugin.link("myurl", "mytitle")
  end

  def test_image
    assert_equal "![myurl](myurl)", plugin.image("myurl")
    assert_equal "![myalt](myurl)", plugin.image("myurl", "myalt")
  end

  def test_render_md
    act = plugin.render_md page, nil
    exp = "<p>Not really much here to see.</p>\n"

    assert_equal exp, act
  end

  def test_render_md_content
    skip "not yet"
    act = plugin.render_md page, "woot"
    exp = "<p>Not really much here to see.</p>\n"

    assert_equal exp, act
  end

  def test_markdown
    act = plugin.markdown "woot"
    exp = "<p>woot</p>\n"

    assert_equal exp, act
  end

  def test_sitemap
    build_fake_site %w[a/index.html
                       a/b/index.html
                       a/b/2012-01-02-p1.html
                       a/b/2012-02-03-p2.html
                       a/b/2012-03-04-p3.html]

    page = site.pages["a/index.html"]
    renderer = Zenweb::MarkdownPlugin.new
    renderer.underlying_page = page
    act  = renderer.sitemap
    exp  = <<-END.cleanup
    * [Title for a/b/index.html](/a/b/)
      * 2012-03:
        * [Title for a/b/2012-03-04-p3.html](/a/b/2012/03/04/p3.html)
      * 2012-02:
        * [Title for a/b/2012-02-03-p2.html](/a/b/2012/02/03/p2.html)
      * 2012-01:
        * [Title for a/b/2012-01-02-p1.html](/a/b/2012/01/02/p1.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_multidir
    build_fake_site %w[a/index.html
                       a/b/index.html
                       a/b/p1.html
                       a/b/p2.html
                       a/b/p3.html]

    page = site.pages["a/index.html"]
    renderer = Zenweb::MarkdownPlugin.new
    renderer.underlying_page = page
    act  = renderer.sitemap
    exp = <<-END.cleanup
    * [Title for a/b/index.html](/a/b/)
      * [Title for a/b/p1.html](/a/b/p1.html)
      * [Title for a/b/p2.html](/a/b/p2.html)
      * [Title for a/b/p3.html](/a/b/p3.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir
    build_fake_site %w[a/index.html
                       a/b/index.html
                       a/b/p1.html
                       a/b/p2.html
                       a/b/p3.html]

    page = site.pages["a/b/index.html"]
    renderer = Zenweb::MarkdownPlugin.new
    renderer.underlying_page = page
    act  = renderer.sitemap
    exp = <<-END.cleanup
    * [Title for a/b/p1.html](/a/b/p1.html)
    * [Title for a/b/p2.html](/a/b/p2.html)
    * [Title for a/b/p3.html](/a/b/p3.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir_mixed
    build_fake_site %w[index.html
                       a/index.html
                       a/a.html
                       a/b.html
                       a/c.html
                       a/2012-01-02-p1.html
                       a/2012-01-03-p2.html
                       a/2012-01-04-p3.html
                       a/2012-02-02-p1.html
                       a/2012-02-03-p2.html
                       a/2012-02-04-p3.html
                       c/index.html
                       c/a.html
                       c/b.html
                       c/c.html
                       c/d/index.html
                       c/d/e.html
                       c/d/f.html
                       c/d/g.html
                       d/index.html
                       d/2012-01-02-p1.html
                       d/2012-01-03-p2.html
                       d/2012-01-04-p3.html
                       some_random_page.html
                      ]

    page = site.pages["index.html"]
    renderer = Zenweb::MarkdownPlugin.new
    renderer.underlying_page = page
    act  = renderer.sitemap
    exp = <<-END.cleanup
    * [Title for a/index.html](/a/)
      * [Title for a/a.html](/a/a.html)
      * [Title for a/b.html](/a/b.html)
      * [Title for a/c.html](/a/c.html)
      * 2012-02:
        * [Title for a/2012-02-04-p3.html](/a/2012/02/04/p3.html)
        * [Title for a/2012-02-03-p2.html](/a/2012/02/03/p2.html)
        * [Title for a/2012-02-02-p1.html](/a/2012/02/02/p1.html)
      * 2012-01:
        * [Title for a/2012-01-04-p3.html](/a/2012/01/04/p3.html)
        * [Title for a/2012-01-03-p2.html](/a/2012/01/03/p2.html)
        * [Title for a/2012-01-02-p1.html](/a/2012/01/02/p1.html)
    * [Title for c/index.html](/c/)
      * [Title for c/a.html](/c/a.html)
      * [Title for c/b.html](/c/b.html)
      * [Title for c/c.html](/c/c.html)
      * [Title for c/d/index.html](/c/d/)
        * [Title for c/d/e.html](/c/d/e.html)
        * [Title for c/d/f.html](/c/d/f.html)
        * [Title for c/d/g.html](/c/d/g.html)
    * [Title for d/index.html](/d/)
      * 2012-01:
        * [Title for d/2012-01-04-p3.html](/d/2012/01/04/p3.html)
        * [Title for d/2012-01-03-p2.html](/d/2012/01/03/p2.html)
        * [Title for d/2012-01-02-p1.html](/d/2012/01/02/p1.html)
    * [Title for some_random_page.html](/some_random_page.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir_bloggish
    build_fake_site %w[index.html
                       2012-01-02-p1.html
                       2012-01-03-p2.html
                       2012-01-04-p3.html
                       2012-02-02-p1.html
                       2012-02-03-p2.html
                       2012-02-04-p3.html
                       sitemap.html
                       some_random_page.html
                      ]

    page = site.pages["index.html"]
    renderer = Zenweb::MarkdownPlugin.new
    renderer.underlying_page = page
    act  = renderer.sitemap
    exp = <<-END.cleanup
    * [Title for sitemap.html](/sitemap.html)
    * [Title for some_random_page.html](/some_random_page.html)
    * 2012-02:
      * [Title for 2012-02-04-p3.html](/2012/02/04/p3.html)
      * [Title for 2012-02-03-p2.html](/2012/02/03/p2.html)
      * [Title for 2012-02-02-p1.html](/2012/02/02/p1.html)
    * 2012-01:
      * [Title for 2012-01-04-p3.html](/2012/01/04/p3.html)
      * [Title for 2012-01-03-p2.html](/2012/01/03/p2.html)
      * [Title for 2012-01-02-p1.html](/2012/01/02/p1.html)
    END

    assert_equal exp, act
  end

  def test_toc
    assert_equal "* \n{:toc}\n", plugin.toc
  end
end

class String
  def cleanup indent = 4
    self.gsub(/^\ {#{indent}}/, '').chomp
  end
end

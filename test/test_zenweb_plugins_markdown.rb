#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageMarkdown < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def test_render_md
    act = page.render_md page, nil
    exp = "<p>Not really much here to see.</p>\n"

    assert_equal exp, act
  end

  def test_render_md_content
    skip "not yet"
    act = page.render_md page, "woot"
    exp = "<p>Not really much here to see.</p>\n"

    assert_equal exp, act
  end

  def test_markdown
    act = page.markdown "woot"
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
    act  = page.sitemap
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
    act = page.sitemap
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
    act = page.sitemap
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
                       b/index.html
                       b/2012-01-02-p1.html
                       b/2012-01-03-p2.html
                       b/2012-01-04-p3.html
                       b/2012-02-02-p1.html
                       b/2012-02-03-p2.html
                       b/2012-02-04-p3.html
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
    act = page.sitemap
    exp = <<-END.cleanup
    * [Title for a/index.html](/a/)
      * [Title for a/a.html](/a/a.html)
      * [Title for a/b.html](/a/b.html)
      * [Title for a/c.html](/a/c.html)
    * [Title for b/index.html](/b/)
      * 2012-02:
        * [Title for b/2012-02-04-p3.html](/b/2012/02/04/p3.html)
        * [Title for b/2012-02-03-p2.html](/b/2012/02/03/p2.html)
        * [Title for b/2012-02-02-p1.html](/b/2012/02/02/p1.html)
      * 2012-01:
        * [Title for b/2012-01-04-p3.html](/b/2012/01/04/p3.html)
        * [Title for b/2012-01-03-p2.html](/b/2012/01/03/p2.html)
        * [Title for b/2012-01-02-p1.html](/b/2012/01/02/p1.html)
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

  def test_toc
    assert_equal "* \n{:toc}\n", page.toc
  end
end

class String
  def cleanup indent = 4
    self.gsub(/^\ {#{indent}}/, '').chomp
  end
end

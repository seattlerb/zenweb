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

  def test_dated_sitemap
    site.scan

    page = site.pages["blog/index.html.erb"]
    act = page.dated_sitemap page.subpages
    exp = <<-END.cleanup
    {:.day}
    ## 2012-01

    * [2012-01-02 ~ Example Page 1](/blog/2012/01/02/page1.html)
    * [2012-01-03 ~ Example Page 2](/blog/2012/01/03/page2.html)
    * [2012-01-04 ~ Example Page 3](/blog/2012/01/04/page3.html)
    END

    assert_equal exp, act
  end

  def xtest_dated_sitemap
    build_fake_site %w[a/index.html
                       a/b/index.html
                       a/b/2012-01-02-p1.html
                       a/b/2012-01-03-p2.html
                       a/b/2012-01-04-p3.html]

    page = site.pages["a/index.html"]
    act = page.dated_sitemap page.subpages
    exp = <<-END.cleanup
    * [Title for a/index.html](/a/index.html)
      * [Title for a/b/index.html](/a/b/index.html)
          * [Title for a/b/2012-01-02-p1.html](/a/b/2012/01/02/p1.html)
          * [Title for a/b/2012-01-03-p2.html](/a/b/2012/01/03/p2.html)
          * [Title for a/b/2012-01-04-p3.html](/a/b/2012/01/04/p3.html)
    END

    assert_equal exp, act

  end

  def test_sitemap
    build_fake_site %w[a/index.html
                       a/b/index.html
                       a/b/2012-01-02-p1.html
                       a/b/2012-01-03-p2.html
                       a/b/2012-01-04-p3.html]

    page = site.pages["a/index.html"]
    act = page.sitemap page.subpages

    exp = <<-END.cleanup
    * [Title for a/b/index.html](/a/b/index.html)
      * [Title for a/b/2012-01-02-p1.html](/a/b/2012/01/02/p1.html)
      * [Title for a/b/2012-01-03-p2.html](/a/b/2012/01/03/p2.html)
      * [Title for a/b/2012-01-04-p3.html](/a/b/2012/01/04/p3.html)
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
    act = page.sitemap page.subpages
    exp = <<-END.cleanup
    * [Title for a/b/index.html](/a/b/index.html)
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
    act = page.sitemap page.subpages
    exp = <<-END.cleanup
    * [Title for a/b/p1.html](/a/b/p1.html)
    * [Title for a/b/p2.html](/a/b/p2.html)
    * [Title for a/b/p3.html](/a/b/p3.html)
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

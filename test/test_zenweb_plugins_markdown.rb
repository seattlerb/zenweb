#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageMarkdown < Minitest::Test
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def test_attr_h
    assert_equal "{:blah=\"42\"}", page.attr("blah" => 42)
  end

  def test_attr_name
    assert_equal "{:blah}", page.attr("blah")
  end

  def test_css_class
    assert_equal "{:.blah}", page.css_class("blah")
  end

  def test_css_id
    assert_equal "{:#blah}", page.css_id("blah")
  end

  def test_link
    assert_equal "[mytitle](myurl)", page.link("myurl", "mytitle")
  end

  def test_image
    assert_equal "![myurl](myurl)", page.image("myurl")
    assert_equal "![myalt](myurl)", page.image("myurl", "myalt")
  end

  def test_render_md
    act = page.render_md page, nil
    exp = "<p>Not really much here to see.</p>\n"

    assert_equal exp, act
  end

  def test_render_md_content
    act = page.render_md page, "woot"
    exp = "<p>woot</p>\n"

    assert_equal exp, act
  end

  def test_markdown
    act = page.markdown "woot"
    exp = "<p>woot</p>\n"

    assert_equal exp, act
  end

  def test_sitemap
    build_fake_site %w[a/index.html.md
                       a/b/index.html.md
                       a/b/2012-01-02-p1.html
                       a/b/2012-02-03-p2.html
                       a/b/2012-03-04-p3.html]

    page = site.pages["a/index.html.md"]
    act  = page.sitemap
    exp  = <<-END.cleanup
    * [Title for a/b/index.html.md](/a/b/)
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
    build_fake_site %w[a/index.html.md
                       a/b/index.html.md
                       a/b/p1.html
                       a/b/p2.html
                       a/b/p3.html]

    page = site.pages["a/index.html.md"]
    act = page.sitemap
    exp = <<-END.cleanup
    * [Title for a/b/index.html.md](/a/b/)
      * [Title for a/b/p1.html](/a/b/p1.html)
      * [Title for a/b/p2.html](/a/b/p2.html)
      * [Title for a/b/p3.html](/a/b/p3.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir
    build_fake_site %w[a/index.html
                       a/b/index.html.md
                       a/b/p1.html
                       a/b/p2.html
                       a/b/p3.html]

    page = site.pages["a/b/index.html.md"]
    act = page.sitemap
    exp = <<-END.cleanup
    * [Title for a/b/p1.html](/a/b/p1.html)
    * [Title for a/b/p2.html](/a/b/p2.html)
    * [Title for a/b/p3.html](/a/b/p3.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir_mixed
    build_fake_site %w[index.html.md
                       a/index.html.md
                       a/a.html
                       a/b.html
                       a/c.html
                       a/2012-01-02-p1.html
                       a/2012-01-03-p2.html
                       a/2012-01-04-p3.html
                       a/2012-02-02-p1.html
                       a/2012-02-03-p2.html
                       a/2012-02-04-p3.html
                       c/index.html.md
                       c/a.html
                       c/b.html
                       c/c.html
                       c/d/index.html.md
                       c/d/e.html
                       c/d/f.html
                       c/d/g.html
                       d/index.html.md
                       d/2012-01-02-p1.html
                       d/2012-01-03-p2.html
                       d/2012-01-04-p3.html
                       some_random_page.html
                      ]

    page = site.pages["index.html.md"]
    act = page.sitemap
    exp = <<-END.cleanup
    * [Title for a/index.html.md](/a/)
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
    * [Title for c/index.html.md](/c/)
      * [Title for c/a.html](/c/a.html)
      * [Title for c/b.html](/c/b.html)
      * [Title for c/c.html](/c/c.html)
      * [Title for c/d/index.html.md](/c/d/)
        * [Title for c/d/e.html](/c/d/e.html)
        * [Title for c/d/f.html](/c/d/f.html)
        * [Title for c/d/g.html](/c/d/g.html)
    * [Title for d/index.html.md](/d/)
      * 2012-01:
        * [Title for d/2012-01-04-p3.html](/d/2012/01/04/p3.html)
        * [Title for d/2012-01-03-p2.html](/d/2012/01/03/p2.html)
        * [Title for d/2012-01-02-p1.html](/d/2012/01/02/p1.html)
    * [Title for some_random_page.html](/some_random_page.html)
    END

    assert_equal exp, act
  end

  def test_sitemap_subdir_bloggish
    build_fake_site %w[index.html.md
                       2012-01-02-p1.html
                       2012-01-03-p2.html
                       2012-01-04-p3.html
                       2012-02-02-p1.html
                       2012-02-03-p2.html
                       2012-02-04-p3.html
                       sitemap.html
                       some_random_page.html
                      ]

    page = site.pages["index.html.md"]
    act = page.sitemap
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
    assert_equal "* \n{:toc}\n", page.toc
  end
end

class String
  def cleanup indent = 4
    self.gsub(/^\ {#{indent}}/, '').chomp
  end
end

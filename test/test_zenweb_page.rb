#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"

describe Zenweb::Page do
  attr_accessor :site, :page

  def setup
    @old_dir = Dir.pwd
    Dir.chdir "example-site"

    self.site = Zenweb::Site.new
    site.scan

    self.page = site.pages["blog/2012-01-02-page1.html.md"]
  end

  def teardown
    Dir.chdir @old_dir
  end

  def test_body
    assert_equal "Not really much here to see.", page.body
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

  def test_depended_on_by
    skip 'not yet'
    assert_equal 42, page.depended_on_by
    flunk 'not yet'
  end

  def test_depends_on
    skip 'not yet'
    assert_equal 42, page.depends_on
    flunk 'not yet'
  end

  def test_filetype
    assert_equal "md", page.filetype
  end

  def test_filetypes
    assert_equal %w[md], page.filetypes
  end

  def test_generate
    skip 'not yet'
    assert_equal 42, page.generate
    flunk 'not yet'
  end

  def test_include
    fragment = page.include("analytics.html")
    assert_match(/UA-\d+/, site.config["google_ua"])
    # assert_match site.config["google_ua"], fragment # HACK
  end

  def test_index
    assert_equal page.config["title"], page["title"]
  end

  def test_inspect
    assert_equal 'Page["blog/2012-01-02-page1.html.md"]', page.inspect
  end

  def test_layout
    assert_equal site.layout("post"), page.layout
  end

  def test_method_missing
    assert_equal page["title"], page.method_missing("title")
  end

  def test_path
    assert_equal "blog/2012-01-02-page1.html.md", page.path
  end

  def test_render
    assert_equal "<p>Not really much here to see.</p>\n", page.render
  end

  def test_renderer_extensions # FIX: this should be a class method
    assert_equal %w(erb less md), page.renderer_extensions.sort
  end

  def test_site
    assert_equal site, page.site
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

  def test_url_dir
    assert_equal ".site/blog/2012/01/02", page.url_dir
  end

  def test_url_path
    assert_equal ".site/blog/2012/01/02/page1.html", page.url_path
  end

  def test_wire
    skip 'not yet'
    assert_equal 42, page.wire
    flunk 'not yet'
  end
end

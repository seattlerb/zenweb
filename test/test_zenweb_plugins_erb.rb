#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageErb < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def test_render_erb
    act = page.render_erb page, nil
    exp = "Not really much here to see."

    assert_equal exp, act
  end

  def test_erb
    act = page.erb "this is some content", page
    exp = "this is some content"

    assert_equal exp, act
  end

  def test_erb_embedded
    act = page.erb "this is {{ 1 + 1 }} content", page
    exp = "this is 2 content"

    assert_equal exp, act
  end

  def test_erb_other_error
    e = assert_raises RuntimeError do
      page.erb "this is {{ raise 'no' }} content", page
    end

    assert_equal "no", e.message

    exp = ['Page["blog/2012-01-02-page1.html.md"]:1']
    assert_equal exp, e.backtrace
  end

  def test_erb_syntax_error
    e = assert_raises SyntaxError do
      page.erb "this is {{ 1 + }} content", page
    end

    assert_includes e.message, "concat(( 1 + ).to_s)"
    exp = ['Page["blog/2012-01-02-page1.html.md"]:1']
    assert_equal exp, e.backtrace
  end
end

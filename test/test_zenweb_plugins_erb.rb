#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageErb < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page, :plugin

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
    self.plugin = Zenweb::ErbPlugin.new
    self.plugin.underlying_page = page
  end

  def test_render_erb
    act = plugin.render_erb page, nil
    exp = "Not really much here to see."

    assert_equal exp, act
  end

  def test_erb
    act = plugin.erb "this is some content", page
    exp = "this is some content"

    assert_equal exp, act
  end

  def test_erb_embedded
    act = plugin.erb "this is {{ 1 + 1 }} content", page
    exp = "this is 2 content"

    assert_equal exp, act
  end

  def test_erb_other_error
    e = assert_raises RuntimeError do
      plugin.erb "this is {{ raise 'no' }} content", page
    end

    assert_equal "no", e.message

    assert e.backtrace.grep('Page["blog/2012-01-02-page1.html.md"]:1')
  end

  def test_erb_syntax_error
    e = assert_raises SyntaxError do
      plugin.erb "this is {{ 1 + }} content", page
    end

    assert_includes e.message, "concat(( 1 + ).to_s)"
    assert e.backtrace.grep('Page["blog/2012-01-02-page1.html.md"]:1')
  end
end

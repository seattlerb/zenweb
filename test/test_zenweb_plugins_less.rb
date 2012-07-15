#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageLess < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page, :plugin

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
    self.plugin = Zenweb::LessPlugin.new
    self.plugin.underlying_page = page
  end

  def test_render_less
    skip "soooo fucking slow!" unless ENV["RCOV"]
    css = "h1 {color: red}"
    act = nil

    capture_io do # TODO: why?
      act = plugin.render_less page, css
    end
    exp = "h1 { color: red; }\n"

    assert_equal exp, act
  end
end

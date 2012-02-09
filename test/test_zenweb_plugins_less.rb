#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageLess < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def test_render_less
    skip "soooo fucking slow!"
    page.content = "h1 {color: red}"
    act = page.render_less page, nil
    exp = "h1 { color: red; }\n"

    assert_equal exp, act
  end
end

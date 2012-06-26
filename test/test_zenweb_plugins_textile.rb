#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageTextile < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-05-page4.html.textile"
  end

  def test_render_textile
    act = page.render_textile page, nil
    exp = "<p>Not really <strong>much</strong> here to see.</p>"

    assert_equal exp, act
  end

  def test_textile
    act = page.textile "this is *some* content"
    exp = "<p>this is <strong>some</strong> content</p>"

    assert_equal exp, act
  end

end

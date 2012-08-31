#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageHaml < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "pages/haml-devs-need-to-look-at-ruby-warnings.html.haml"
  end

  def test_render_haml
    act = page.render_haml page, nil
    exp = "<div>Not really much here to see.</div>\n"

    assert_equal exp, act
  end

  def test_haml
    act = page.haml "%div foo fah\n"
    exp = "<div>foo fah</div>\n"

    assert_equal exp, act
  end
end

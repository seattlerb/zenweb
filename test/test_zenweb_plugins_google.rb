#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageGoogle < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"

    site.config.h["google_ad_client"] = "mygooglethingy"
  end

  def test_render_google_ad
    exp = <<-EOM.gsub(/^ {6}/, '')
      <script><!--
      google_ad_client = "mygooglethingy";
      google_ad_slot   = "myslot";
      google_ad_width  = 1;
      google_ad_height = 2;
      //-->
      </script>
      <script src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
      </script>
    EOM

    assert_equal exp, page.google_ad("myslot", 1, 2)
  end
end

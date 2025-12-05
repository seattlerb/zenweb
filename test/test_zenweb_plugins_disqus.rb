#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebPageDisqus < Minitest::Test
  attr_accessor :site, :page

  def setup
    super

    self.site = Zenweb::Site.new
    self.page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
  end

  def js name
    <<-EOM.gsub(/^ {6}/, '')
      <script type=\"text/javascript\">
        (function() {
          var s   = document.createElement('script');
          s.type  = 'text/javascript';
          s.async = true;
          s.src   = 'https://myshortname.disqus.com/#{name}.js';
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(s);
        })();
      </script>
    EOM
  end

  def test_render_disqus
    div = "<div id=\"disqus_thread\"></div>"
    assert_equal div + js("embed"), page.disqus("myshortname")
  end

  def test_render_disqus_counts
    assert_equal js("count"), page.disqus_counts("myshortname")
  end
end

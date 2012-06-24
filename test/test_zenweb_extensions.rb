#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"
require "zenweb/extensions"

class TestFile < MiniTest::Unit::TestCase
  def test_class_each_parent
    a = []

    Dir.chdir "example-site" do
      File.each_parent "blog/index.html.erb", "_config.yml" do |f|
        a << f
      end
    end

    assert_equal %w[blog/_config.yml _config.yml], a
  end
end

class TestTime < MiniTest::Unit::TestCase
  def test_date
    assert_equal "1969-12-31",         Time.local(1969,12,31,16,0).date
  end

  def test_datetime
    assert_equal "1969-12-31 @ 16:00", Time.local(1969,12,31,16,0).datetime
  end

  def test_time
    assert_equal "16:00",              Time.local(1969,12,31,16,0).time
  end
end

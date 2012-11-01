#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"
require "zenweb/extensions"

class TestArray < MiniTest::Unit::TestCase
  def test_deep_each
    act = []
    [1, 2, [3, [4], 5], 6].deep_each do |n, o|
      act << [o, n]
    end

    exp = [[1, 0], [2, 0], [3, 1], [4, 2], [5, 1], [6, 0]]
    assert_equal exp, act
  end

  def test_deep_each_enum
    act = [1, 2, [3, [4], 5], 6].deep_each.map { |n, o|
      [o, n]
    }

    exp = [[1, 0], [2, 0], [3, 1], [4, 2], [5, 1], [6, 0]]
    assert_equal exp, act
  end

  def test_chunk
    act = [3,1,4,1,5,9,2,6,5,3,5].chunk {|n| n.even? }.to_a
    exp = [[false, [3, 1]],
           [true,  [4]],
           [false, [1, 5, 9]],
           [true,  [2, 6]],
           [false, [5, 3, 5]]]

    assert_equal exp, act
  end
end

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

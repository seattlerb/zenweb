#!/usr/bin/ruby -w

require "rubygems"

gem "rake"
require "rake"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class TestZenwebConfig < MiniTest::Unit::TestCase
  include ChdirTest("example-site")

  attr_accessor :site, :config

  def setup
    super

    self.site = Zenweb::Site.new
    page = Zenweb::Page.new site, "blog/2012-01-02-page1.html.md"
    self.config = page.config
  end

  def test_h
    exp = {"title"=>"Example Page 1"}
    assert_equal exp, config.h
  end

  def test_index
    assert_equal "Example Page 1", config["title"]
  end

  def test_inspect
    exp = ['Config["blog/2012-01-02-page1.html.md"',
           'Config["blog/_config.yml"',
           'Config["_config.yml"',
           'Config::Null]]]'
          ].join ", "
    assert_equal exp, config.inspect
  end

  def test_inspect_trace
    exp = ['Config["blog/2012-01-02-page1.html.md"',
           'Config["blog/_config.yml"',
           'Config["_config.yml"',
           'Config::Null',
           '"header"=>"Example Website"',
           '"exclude"=>["Rakefile", "tmp"]',
           '"google_ua"=>"UA-1234567-8"]',
           '"layout"=>"post"]',
           '"title"=>"Example Page 1"]'].join ", "

    assert_nil Rake.application.options.trace
    Rake.application.options.trace = true
    assert_equal exp, config.inspect
  ensure
    Rake.application.options.trace = nil
  end

  def test_parent
    assert_equal site.configs["blog/_config.yml"], config.parent
  end

  def test_path
    assert_equal "blog/2012-01-02-page1.html.md", config.path
  end

  def test_site
    assert_equal site, config.site
  end

  def test_to_s
    assert_equal "Config[\"blog/2012-01-02-page1.html.md\"]", config.to_s
  end

  def test_wire
    Rake.application = Rake::Application.new
    site.scan
    self.config = site.pages["blog/2012-01-02-page1.html.md"].config
    rake = Rake.application

    config.wire

    assert_tasks do
      assert_task "", nil, Rake::Task # HACK
      assert_task "_config.yml"
      assert_task "blog/_config.yml", %w[_config.yml]
      assert_task config.path, %w[blog/_config.yml]
    end
  end
end

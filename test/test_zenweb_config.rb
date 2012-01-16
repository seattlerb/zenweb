#!/usr/bin/ruby -w

require "rubygems"

gem "rake"
require "rake"
require "minitest/autorun"

require "zenweb/site"

describe Zenweb::Config do
  attr_accessor :site, :config

  def setup
    @old_dir = Dir.pwd
    Dir.chdir "example-site"

    self.site = Zenweb::Site.new
    site.scan

    self.config = site.pages["blog/2012-01-02-page1.html.md"].config
  end

  def teardown
    Dir.chdir @old_dir
  end

  def test_h
    exp = {"title"=>"Example Page 1"}
    assert_equal exp, config.h
  end

  def test_index
    assert_equal "Example Page 1", config["title"]
  end

  def test_inspect
    exp = ["Config[\"blog/2012-01-02-page1.html.md\"",
           "Config[\"blog/_config.yml\"",
           "Config[\"_config.yml\"",
           "Config::Null]]]"
          ].join ", "
    assert_equal exp, config.inspect
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
    skip 'not yet'
  end
end

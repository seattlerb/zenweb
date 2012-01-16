#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"

class Zenweb::Site
  attr_accessor :layouts
end

describe Zenweb::Site do
  attr_accessor :site

  def setup
    @old_dir = Dir.pwd
    Dir.chdir "example-site"

    self.site = Zenweb::Site.new
  end

  def teardown
    Dir.chdir @old_dir
  end

  def test_categories
    site.scan
    cats = site.categories
    assert_equal %w(blog pages projects), cats.keys.sort

    exp = [["blog/2012-01-02-page1.html.md",
            "blog/2012-01-03-page2.html.md",
            "blog/2012-01-04-page3.html.md"],
           ["projects/zenweb.html.erb"],
           ["pages/nonblogpage.html.md"]]

    assert_equal exp, cats.values.map { |a| a.map(&:path).sort }
  end

  def test_config
    assert_equal "_config.yml", site.config.path
  end

  def test_configs
    site.scan

    exp = %w[_config.yml blog/_config.yml]

    assert_equal exp, site.configs.keys.sort

    exp = [Zenweb::Config]
    assert_equal exp, site.configs.values.map(&:class).uniq
  end

  def test_generate
    skip 'not yet'
  end

  def test_inspect
    # we haven't scanned yet, so fast, but boring
    assert_equal "Site[0 pages, 0 configs]", site.inspect
  end

  def test_layout
    site.scan
    assert_equal "_layouts/post.erb", site.layout("post").path
  end

  def test_method_missing
    assert_equal "Example Website", site.header
  end

  def test_pages
    site.scan

    excludes = %w[Rakefile config.ru]

    exp = Dir["**/*"].
      select { |p| File.file? p }.
      reject! { |p| p =~ /(^|\/)_/ }.
      sort - excludes

    assert_equal exp, site.pages.keys.sort

    exp = [Zenweb::Page]

    assert_equal exp, site.pages.values.map(&:class).uniq
  end

  def test_pages_by_date
    skip "this is a serious bitch of a test to write"
    site.scan

    exp = Dir["**/*.html.*"].
      reject! { |p| p =~ /(^|\/)_/ }.
      sort_by { |p| YAML.load_file(p)["date"] || File.mtime(p) }

    assert_equal exp, site.pages_by_date.map(&:path)

    flunk 'not yet'
  end

  def test_scan # the rest is tested via the other tests
    assert_empty site.pages
    assert_empty site.configs
    assert_empty site.layouts

    site.scan

    refute_empty site.pages
    refute_empty site.configs
    refute_empty site.layouts
  end

  def normalize_path p
    p.sub(/(?:\.(md|erb|less))+$/, '').
      sub(/(\d\d\d\d)-(\d\d)-(\d\d)-/, '\1/\2/\3/')
  end

  def test_wire
    site.scan
    site.wire

    app = Rake.application
    tasks = app.tasks

    exp = [Rake::FileCreationTask, Rake::FileTask, Rake::Task]
    assert_equal exp, tasks.map(&:class).uniq.sort_by { |k| k.name }

    assert_equal "site", Rake.application[:site].name

    exp = %w[.site
             .site/_layouts/post
             .site/_layouts/project
             .site/_layouts/site
             .site/about/index.html
             .site/atom.xml
             .site/blog/2012/01/02/page1.html
             .site/blog/2012/01/03/page2.html
             .site/blog/2012/01/04/page3.html
             .site/blog/index.html
             .site/css/colors.css
             .site/css/styles.css
             .site/css/syntax.css
             .site/img/bg.png
             .site/index.html
             .site/js/jquery.js
             .site/js/site.js
             .site/pages/index.html
             .site/pages/nonblogpage.html
             .site/projects/index.html
             .site/projects/zenweb.html
             .site/sitemap.xml]

    # HACK: _layouts shouldn't be in there... fix that
    assert_equal exp, Rake.application[:site].prerequisites.sort
  end
end

require "rubygems"
gem "rake"
require "rake"

require "zenweb/page"
require "zenweb/config"
require "zenweb/extensions"

module Zenweb
  class Site
    include Rake::DSL

    attr_reader :pages, :configs

    def self.load_plugins
      Gem.find_files("zenweb/plugins/*.rb").each do |path|
        require path
      end
    end

    self.load_plugins

    def initialize
      @pages = {}
      @configs = Hash.new { |h,k| h[k] = Config.new self, k }
    end

    def inspect
      "Site[#{pages.size} pages, #{configs.size - pages.size} configs]"
    end

    def config
      configs["_config.yml"]
    end

    def scan
      excludes = Array(config["exclude"])

      top = Dir["*"] - excludes
      files, dirs = top.partition { |path| File.file? path }
      files += Dir["{#{top.join(",")}}/**/*"].reject { |f| not File.file? f }

      @layouts = {}

      renderers_re = Page.renderers_re

      files.each do |path|
        case path
        when /(?:~|#{excludes.join '|'})$/
          # ignore
        when /^_layout/ then
          ext = File.extname path
          name = File.basename path, ext
          @layouts[name] = Page.new self, path
        when /^_/ then
          next
        when /\.yml$/ then
          Config.new self, path
        when /\.(?:txt|html|css|js|png|jpg|gif|eot|svg|ttf|woff|ico)$/, renderers_re then # HACK
          Page.new self, path
        else
          warn "unknown file type: #{path}" if Rake.application.options.trace
        end
      end
    end

    def layout name
      @layouts[name]
    end

    def wire
      directory ".site"
      task :site => ".site"

      configs.each do |path, config|
        config.wire
      end

      pages.each do |path, page|
        page.wire
      end

      $website = self # HACK
      task(:extra_wirings).invoke
    end

    def generate
      task(:site).invoke
    end

    def pages_by_date
      pages.values.select {|p| p["title"] && p.date }.sort_by(&:date).reverse
    end

    def categories
      @categories ||=
        begin
          h = Hash.new { |h,k| h[k] = [] }

          def h.method_missing msg, *args
            if self.has_key? msg.to_s then
              self[msg.to_s]
            else
              super
            end
          end

          pages.each do |url, page|
            dir = url.split(/\//).first
            next unless File.directory? dir and dir !~ /^_/
            next if url =~ /index.html/
            h[dir] << page
          end

          h.keys.each do |dir|
            h[dir] = h[dir].sort_by(&:date).reverse
          end

          h
        end
    end
  end # class Site
end

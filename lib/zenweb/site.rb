require "rubygems"
gem "rake"
require "rake"

require "zenweb/page"
require "zenweb/config"
require "zenweb/extensions"

module Zenweb

  ##
  # Holder for the entire website. Everything gets driven from here.
  #
  # TODO: describe expected filesystem layout and dependency mgmt.

  class Site
    include Rake::DSL

    ##
    # Returns all pages found via #scan

    attr_reader :pages

    ##
    # Returns all configs found via #scan

    attr_reader :configs

    ##
    # Loads all files matching "zenweb/plugins/*.rb".

    def self.load_plugins
      Gem.find_files("zenweb/plugins/*.rb").each do |path|
        require path
      end
    end

    self.load_plugins

    def initialize # :nodoc:
      @layouts = {}
      @pages = {}
      @configs = Hash.new { |h,k| h[k] = Config.new self, k }
    end

    ##
    # Returns a magic hash that groups up all the pages by category
    # (directory). The hash has extra accessor methods on it to make
    # grabbing what you want a bit cleaner. eg:
    #
    #    site.categories.blog # => [Page[blog/...], ...]

    def categories
      @categories ||=
        begin
          h = Hash.new { |h2,k| h2[k] = [] }

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
            next if url =~ /index.html/ or url !~ /html/
            h[dir] << page
          end

          h.keys.each do |dir|
            h[dir] = h[dir].sort_by { |p| [-p.date.to_i, p.title ] }
          end

          h
        end
    end

    ##
    # Return the top level config.

    def config
      configs["_config.yml"]
    end

    ##
    # Generates the website by invoking the 'site' task.

    def generate
      task(:site).invoke
    end

    ##
    # Returns a list of all known html pages.

    def html_pages
      self.pages.values.select { |p| p.url_path =~ /\.html/ }
    end

    def inspect # :nodoc:
      "Site[#{pages.size} pages, #{configs.size} configs]"
    end

    ##
    # Returns a layout named +name+.

    def layout name
      @layouts[name]
    end

    ##
    # Proxy object for the config. Returns a config item at +msg+.

    def method_missing msg, *args
      config[msg.to_s] || warn("#{self.inspect} does not define #{msg}")
    end

    ##
    # Returns all pages (with titles) sorted by date.

    def pages_by_date
      # page.config["title"] avoids the warning
      html_pages.select {|page| page.config["title"] && page.date }.
        sort_by { |page| [-page.date.to_i, page.title] }
    end

    ##
    # Scans the directory tree and finds all relevant pages, configs,
    # layouts, etc.
    #
    # TODO: talk about expected directory structure and extra
    # naming enhancements.

    def scan
      excludes = Array(config["exclude"])

      top = Dir["*"] - excludes
      files = top.select { |path| File.file? path }
      files += Dir["{#{top.join(",")}}/**/*"].reject { |f| not File.file? f }

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
          @configs[path] = Config.new self, path
        when /\.(?:png|jpg|gif|eot|svg|ttf|woff|ico)$/ then # HACK
          @pages[path] = Page.new self, path, self.config
        when /\.(?:txt|html|css|js)$/, renderers_re then # HACK
          @pages[path] = Page.new self, path
        else
          warn "unknown file type: #{path}" if Rake.application.options.trace
        end
      end
    end

    ##
    # Wire up all the configs and pages. Invokes :extra_wirings to
    # allow you to add extra manual dependencies.

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
  end # class Site
end

require "rubygems"

gem "rake"
require "rake"

module Zenweb
  class Page
    include Rake::DSL

    attr_reader :site, :path

    def initialize site, path
      @site, @path = site, path
      site.pages[path] = self
    end

    def config
      unless defined? @config then
        @config = Config.new site, path
        @config = @config.parent unless content =~ /\A---/
      end
      @config
    end

    def layout
      unless defined? @layout then
        @layout = site.layout self.config["layout"]
      end
      @layout
    end

    def content
      @content ||= File.read path
    end

    def body
      @body ||= content.split(/^---$/, 3).last.strip
    end

    def inspect
      "Page[#{path.inspect}]"
    end

    alias :to_s :inspect

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self

      conf = self.config
      conf = conf.parent if self.path == conf.path

      file self => conf
      conf.wire

      if self.layout then
        file self => self.layout
        self.layout.wire
      end

      unless url_dir =~ %r%/_% then
        directory url_dir
        file url_path => url_dir
        file url_path => path do
          self.generate
        end
      end

      # This flattens out the deps so that the html file will be
      # rebuild if a config file up the dep tree is rebuilt. This is
      # currently needed because a source file isn't rebuilt if one of
      # it's dependent configs is modified.
      file(url_path).enhance task(self).prerequisites

      task :site => url_path
    end

    def self.renderer_extensions
      @ext ||=
        instance_methods.grep(/^render_/).map { |s| s.sub(/render_/, '') }
    end

    def renderer_extensions # HACK remove me as we refactor to classes
      self.class.renderer_extensions
    end

    def self.renderers_re # HACK
      @renderers_re ||= /(?:\.(#{renderer_extensions.join "|"}))+$/
    end

    def url
      self.path.
        sub(/^/, '/').
        sub(/(\d\d\d\d)-(\d\d)-(\d\d)-/, '\1/\2/\3/').
        gsub(self.class.renderers_re, '')
    end

    def url_path
      @url_path ||= File.join(".site", self.url)
    end

    def url_dir
      File.dirname url_path
    end

    def filetype name = self.path
      File.extname(name)[1..-1]
    end

    def render page = self, content = nil
      content = subrender page, content

      layout  = self.layout # TODO: make nullpage to avoid 'if layout' tests
      content = layout.render page, content if layout

      content
    end

    def subrender page = self, content = nil
      filetypes.inject(content) { |cont, type|
        send "render_#{type}", page, cont
      } || self.content
    end

    def filetypes
      @filetypes ||= path[self.class.renderers_re].split(/\./)[1..-1].reverse
    rescue
      []
    end

    def [] k
      config[k.to_s]
    end

    def method_missing msg, *args
      case msg.to_s
      when /^render_/ then
        super
      else
        self[msg] || warn("#{self.inspect} does not define #{msg}")
      end
    end

    def date
      config['date'] || date_from_path || File.stat(path).mtime
    end

    def date_from_path
      date = path[/\d\d\d\d-\d\d-\d\d/]
      Time.local(*date.split(/-/).map(&:to_i)) if date
    end

    def include path
      File.read File.join("_includes", path)
    end

    def generate
      warn "Rendering #{path}"
      warn "       to #{url_path}"

      content = self.render

      File.open url_path, "w" do |f|
        f.puts content
      end
    end

    def xml_escape content
      require 'cgi'
      CGI.escapeHTML content
    end
  end # class Page
end

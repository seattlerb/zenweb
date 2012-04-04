require "rubygems"

gem "rake"
require "rake"

module Zenweb

  ##
  # Page represents pretty much any type of file that goes on your
  # website or is needed by other pages to build your website. Each
  # page can have a YAML header that contains configuration data or
  # variables used in the page.

  class Page
    include Rake::DSL

    ##
    # The shared site instance.

    attr_reader :site

    ##
    # The path to this source file.

    attr_reader :path

    attr_reader :subpages

    attr_accessor :parent

    ##
    # Returns a regexp that will match file extensions for all known
    # renderer types.

    def self.renderers_re
      @renderers_re ||=
        begin
          ext = instance_methods.grep(/^render_/).map { |s|
            s.to_s.sub(/render_/, '')
          }
          /(?:\.(#{ext.join "|"}))+$/
        end
    end

    def initialize site, path, config = nil # :nodoc:
      # TODO: make sure that creating page /a.html strips leading / from path
      @site, @path = site, path
      @config = config if config
      @subpages = []
    end

    ##
    # Helper method to access the config value named +k+.

    def [] k
      config[k] or warn("#{self.inspect} does not define #{k.inspect}")
    end

    def all_subpages
      subpages.map { |p| [p, p.all_subpages] }.flatten
    end

    ##
    # Returns the actual content of the file minus the optional YAML header.

    def body
      # TODO: add a test for something with --- without a yaml header.
      @body ||= begin
                  _, body, binary = Zenweb::Config.split path
                  (!binary && body.strip) || body
                end
    end

    def parent_url url = self.url
      url = File.dirname url if File.basename(url) == "index.html"
      File.join File.dirname(url), "index.html"
    end

    def breadcrumbs
      pages = [self]
      loop do
        parent = pages.first.parent
        break unless parent and parent != pages.first
        pages.unshift parent
      end
      pages.pop # take self back off
      pages
    end

    ##
    # Return the url as users normally enter them (ie, no index.html).

    def clean_url
      url.sub(/\/index.html$/, '/')
    end

    ##
    # Returns the closest Config instance for this file. That could be
    # the YAML prefix in the file or it could be a _config.yml file in
    # the file's directory or above.

    def config
      unless defined? @config then
        @config = Config.new site, path
        @config = @config.parent unless content.start_with? "---"
      end
      @config
    end

    ##
    # Returns the entire (raw) content of the file.

    def content
      @content ||= File.binread path
    end

    ##
    # Returns either:
    #
    # + The value of the +date+ config value
    # + The date embedded in the filename itself (eg: 2012-01-02-blah.html).
    # + The last modified timestamp of the file itself.

    def date
      config['date'] || date_from_path || File.stat(path).mtime
    end

    def date_from_path # :nodoc:
      date = path[/\d\d\d\d-\d\d-\d\d/]
      Time.local(*date.split(/-/).map(&:to_i)) if date
    end

    def dated?
      config['date'] || date_from_path
    end

    ##
    # Is this a dated page? (ie, does it have YYYY-MM-DD in the path?)

    def dated_path?
      path[/\d\d\d\d-\d\d-\d\d/]
    end

    def html?
      path =~ /\.html/
    end

    ##
    # Wires up additional dependents on this Page. +from_deps+ may be
    # a Hash (eg site.pages), an Array (eg. site.categories.blog), or
    # a single page.
    #
    # This is the opposite of #depends_on and I'm not sure it is
    # actually needed.
    #
    # TODO: remove me?

    def depended_on_by from_deps
      from_deps = from_deps.values if Hash === from_deps
      from_deps = Array(from_deps)

      from_deps.each do |dep|
        next if self.url_path == dep.url_path
        file dep.url_path => self.url_path
      end
    end

    ##
    # Wires up additional dependencies for this Page. +from_deps+ may
    # be a Hash (eg site.pages), an Array (eg. site.categories.blog),
    # or a single page.

    def depends_on deps
      if String === deps then
        file self.path => deps
      else
        deps = deps.values if Hash === deps
        deps = Array(deps)

        file self.url_path => deps.map(&:url_path) - [self.url_path]
      end
    end

    ##
    # Returns the extension (without the '.') of +name+, defaulting to
    # +self.path+.

    def filetype name = self.path
      File.extname(name)[1..-1]
    end

    ##
    # Returns an array of extensions (in reverse order) of this page
    # that match known renderers. For example:
    #
    # Given renderer methods +render_erb+ and +render_md+, the file
    # "index.html.md.erb" would return %w[erb md], but the file
    # "index.html" would return [].
    #
    # Additional renderers can be added via Site.load_plugins.

    def filetypes
      @filetypes ||= path[self.class.renderers_re].split(/\./)[1..-1].reverse
    rescue
      []
    end

    ##
    # Format a date string +s+ using the config value +date_fmt+ or YYYY/MM/DD.

    def format_date s
      fmt = self.config["date_fmt"] || "%Y/%m/%d"
      Time.local(*s.split(/-/).map(&:to_i)).strftime(fmt)
    end

    ##
    # Render and write the result to #url_path.

    def generate
      warn "Rendering #{url_path}"

      content = self.render

      open url_path, "w" do |f|
        f.puts content
      end
    end

    ##
    # Render a named file from +_includes+.
    #
    # category: XXX

    def include name, page
      incl = Page.new(site, File.join("_includes", name))
      incl.subrender page
    end

    def index?
      url.end_with? "index.html"
    end

    def inspect # :nodoc:
      "Page[#{path.inspect}]"
    end

    alias :to_s :inspect # :nodoc:

    ##
    # Return a layout Page named in the config key +layout+.
    #
    # TODO: expand

    def layout
      unless defined? @layout then
        @layout = site.layout self.config["layout"]
      end
      @layout
    end

    ##
    # Convenience function to create an html link for this page.

    def link_html title = self.title
      %(<a href="#{clean_url}">#{title}</a>)
    end

    ##
    # Stupid helper method to make declaring header meta lines cleaner

    def meta key, name=key, label="name"
      val = self.config[key]
      %(<meta #{label}="#{name}" content="#{val}">) if val
    end

    ##
    # Access a config variable and only warn if it isn't accessible.
    # If +msg+ starts with render, go ahead and pass that up to the
    # default method_missing.

    def method_missing msg, *args # :nodoc:
      case msg.to_s
      when /=|^render_|^to_a(?:ry)?$/ then # to_a/ry for 1.9 only. :(
        super
      else
        self[msg]
      end
    end

    ##
    # Render this page as a whole. This includes rendering the page's
    # content into a layout if one has been specified via config.

    def render page = self, content = nil
      content = subrender page, content

      layout  = self.layout # TODO: make nullpage to avoid 'if layout' tests
      content = layout.render page, content if layout

      content
    end

    ##
    # Render a Page instance based on its filetypes. For example,
    # index.html.md.erb will essentially call:
    #
    #     render_md(render_erb(content))

    def subrender page = self, content = nil
      self.filetypes.inject(content) { |cont, type|
        send "render_#{type}", page, cont
      } || self.body
    end

    ##
    # Return the url for this page. The url is based entirely on its
    # location in the file-system.
    #
    # TODO: expand

    def url
      @url ||= self.path.
        sub(/^/, '/').
        sub(/(\d\d\d\d)-(\d\d)-(\d\d)-/) { |s| "#{format_date s}/" }.
        gsub(self.class.renderers_re, '')
    end

    ##
    # The directory portion of the url.

    def url_dir
      File.dirname url_path
    end

    ##
    # The real file path for the generated file.

    def url_path
      @url_path ||= File.join(".site", self.url)
    end

    ##
    # Wire up this page to the rest of the rake dependencies. If you
    # have extra dependencies for this file (ie, an index page that
    # links to many other pages) you can add them by creating a rake
    # task named +:extra_wirings+ and using #depends_on. Eg:
    #
    #     task :extra_wirings do |x|
    #       site = $website
    #       page = site.pages
    #
    #       page["sitemap.xml.erb"].    depends_on site.html_pages
    #       page["atom.xml.erb"].       depends_on site.pages_by_date.first(30)
    #       page["blog/index.html.erb"].depends_on site.categories.blog
    #     end

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self.path

      conf = self.config
      conf = conf.parent if self.path == conf.path

      file self.path => conf.path if conf.path
      conf.wire

      if self.layout then
        file self.path => self.layout.path
        self.layout.wire
      end

      file url_path => all_subpages.map(&:path) if url =~ /index.html/

      unless url_dir =~ %r%/_% then
        directory url_dir
        file url_path => url_dir
        file url_path => path do
          self.generate
        end

        task :site => url_path
      end
    end
  end # class Page
end

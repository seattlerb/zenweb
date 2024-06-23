require "rubygems"

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

    ##
    # The pages directly below this page. Can be empty.

    attr_reader :subpages

    ##
    # The parent page of this page. Can be nil.

    attr_accessor :parent

    ##
    # Is this file a binary file? Defaults to true if config passed to Page.new.

    attr_accessor :binary
    alias binary? binary

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
      @binary = config

      self.filetypes.each do |type|
        send "extend_#{type}" if self.respond_to? "extend_#{type}"
      end

      @subpages = []
    end

    ##
    # Helper method to access the config value named +k+.

    def [] k
      warn("#{self.url} does not define #{k.inspect}") unless config.key?(k)
      config[k]
    end

    ##
    # All pages below this page, possibly +reversed+, recursively.

    def all_subpages reversed = false
      dated, normal = subpages.partition(&:dated_path?)
      dated = dated.reverse if reversed

      (normal + dated).map { |p| [p, p.all_subpages(reversed)] }
    end

    ##
    # All pages below this page, possibly +reversed+, recursively,
    # with the depth of each subpage relative to the current page.

    def all_subpages_by_level reversed = false
      self.all_subpages(reversed).deep_each.map { |n, p| [(n-1)/2, p] }
    end

    ##
    # Returns the actual content of the file minus the optional YAML header.

    def body
      # TODO: add a test for something with --- without a yaml header.
      @body ||= begin
                  thing = File.file?(path) ? path : self
                  _, body = Zenweb::Config.split thing
                  if self.binary? then
                    body
                  else
                    body.strip
                  end
                end
    end

    ##
    # Returns the parent url of a particular url (or self).

    def parent_url url = self.url
      url = File.dirname url if File.basename(url) == "index.html"
      File.join File.dirname(url), "index.html"
    end

    ##
    # Returns an array of all parent pages of this page, including self.

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
      # TODO: this has the same drawbacks as Config.split
      @content ||= File.read path
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
      # TODO: test
      date = path[/\d\d\d\d-\d\d-\d\d/]
      Time.local(*date.split(/-/).map(&:to_i)) if date
    end

    def date_str
      fmt ||= self.config["date_fmt"] || "%Y-%m" # REFACTOR: yuck
      self.date.strftime fmt
    end

    ##
    # Returns true if this page has a date (via config or within the path).

    def dated?
      config['date'] || date_from_path
    end

    ##
    # Is this a dated page? (ie, does it have YYYY-MM-DD in the path?)

    def dated_path?
      path[/\d\d\d\d[-\/]\d\d[-\/]\d\d/] || path[/\d\d\d\d(?:[-\/]\d\d)?\/index/]
    end

    def change_frequency
      days_old = (Time.now - self.date).to_i / 86400

      case days_old
      when 0...14 then
        "daily"
      when 14...56 then
        "weekly"
      when 56...365 then
        "monthly"
      else
        "yearly"
      end
    end

    ##
    # Returns true if this is an html page.

    def html?
      path =~ /\.html/
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
        if binary? then
          f.print content
        else
          f.puts content
        end
      end
    end

    ##
    # Render a named file from +_includes+. You must pass in the
    # current page. This can make its configuration available
    # accessing it via page.

    def include name, page
      incl = Page.new(site, File.join("_includes", name))
      incl.subrender page
    end

    ##
    # Returns true if this page is an index page.

    def index?
      url.end_with? "index.html"
    end

    def inspect # :nodoc:
      "Page[#{path.inspect}]"
    end

    alias :to_s :inspect # :nodoc:

    ##
    # Return a layout Page named in the config key +layout+.

    def layout
      unless defined? @layout then
        @layout = site.layout self.config["layout"]
      end
      @layout
    rescue => e
      raise e.exception "%s for page %p" % [e.message, path]
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
    # Stupid helper method to make declaring header link lines cleaner

    def link_head **kws
      %(<link #{kws.map { |k,v| "#{k}=#{v.inspect}" }.join " "} />)
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
        if config.key? msg
          config[msg]
        else
          config.send msg, *args
        end
      end
    end

    def no_index?
      config["no_index"]
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

    def stale?
      file(url_path).needed?
    end

    ##
    # Stupid helper method to make declaring stylesheets cleaner

    def stylesheet name
      link_head rel:"stylesheet", type:"text/css", href:"/css/#{name}.css"
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

    # TODO: move this and others to plugins/html_toys.rb (or something)

    def run_js_script url
      <<-"EOM".gsub(/^ {6}/, '')
      <script type="text/javascript">
        (function() {
          var s   = document.createElement('script');
          s.type  = 'text/javascript';
          s.async = true;
          s.src   = '#{url}';
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(s);
        })();
      </script>
      EOM
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

    def tag_pages
      (self.config[:tags] || []).map { |t| Zenweb::TagDetail.all[t] }.compact
    end

    def series_page
      series = self.config[:series]
      Zenweb::SeriesPage.all[series] if series
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

      file url_path => all_subpages.flatten.map(&:url_path) if url =~ /index.html/

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

  ##
  # A page not rooted in an actual file. This lets you synthesize
  # pages directly in rake tasks. Initialize it with a destination
  # path as normal, but then you must set the date and content
  # yourself.

  class FakePage < Page
    attr_accessor :content
    attr_accessor :date
  end

  ##
  # Generates a virtual page with an index of all tags on the given pages.
  # You must subclass and provide a content method.

  class GeneratedIndex < FakePage
    attr_accessor :pages

    def self.collate_by pages, key, default=nil
      pages.multi_group_by { |page| page.config[key] || default }
    end

    def self.generate_all site, dir, pages
      raise NotImplementedError, "Implement #{self}#generate_all"
    end

    def self.page_url page # TODO: hard to do helpers on class methods
      "[#{page.title}](#{page.clean_url})"
    end

    def initialize site, path, pages
      super site, path

      self.pages = pages.select(&:html?)
      self.date  = Time.now

      site.pages[path] = self
    end

    def content
      raise NotImplementedError, "Implement #{self.class}#content"
    end

    def wire
      super
      self.depends_on pages
    end
  end

  class TagIndex < GeneratedIndex
    def self.tags_for pages
      collate_by pages, :tags, "None"
    end

    def self.generate_all site, dir, pages
      self.new site, "#{dir}/index.html.md.erb", pages
    end

    def self.tag_list tag, pages
      r = []
      r << "### #{tag}"
      r << "#{pages.size} pages"
      r << ""
      r << pages.map { |page| "*  #{page.date.date} #{page_url page}" }
      r << ""
      r.join "\n"
    end

    def index
      self.class.tags_for(pages).sort_by { |t,_| t.to_s.downcase }.map { |t, p|
        self.class.tag_list t, p
      }.join "\n"
    end
  end

  ##
  # Generates a virtual page with an index for a given tag on the given pages.
  # You must subclass and provide a content method.

  class TagDetail < TagIndex
    attr_accessor :tag

    def self.all
      @@all ||= {}
    end

    def self.generate_all site, dir, pages
      tags_for(pages).sort.each do |tag, pgs|
        path = tag.downcase.gsub(/\W+/, '')
        self.all[tag] = self.new site, "#{dir}/#{path}.html.md.erb", pgs, tag
      end
    end

    def initialize site, path, pages, tag
      super site, path, pages
      self.tag = tag
    end

    def index
      self.class.tag_list tag, pages
    end
  end

  class SeriesPage < GeneratedIndex
    attr_accessor :series

    def self.all
      @@all ||= {}
    end

    def self.series_for pages
      collate_by pages, :series
    end

    def self.generate_all site, dir, pages
      series_for(pages).sort.each do |series, pgs|
        next unless series
        path = series.downcase.gsub(/\W/, '-')
        path = "#{dir}/#{path}.html.md.erb"
        self.all[series] = self.new(site, path, pgs, series)
      end
    end

    def initialize site, path, pages, series
      super site, path, pages
      self.series = series
    end
  end

  ##
  # Generates a virtual page with monthly index pages.
  # You must subclass and provide a content method.

  class MonthlyPage < GeneratedIndex
    def self.generate_all site, dir, pages
      pages.find_all(&:dated?).group_by { |page|
        [page.date.year, page.date.month]
      }.each do |(year, month), subpages|
        path = "#{dir}/%4d/%02d/index.html.md.erb" % [year, month]
        self.new site, path, subpages, year, month
      end
    end

    def initialize site, path, pages, year, month
      super site, path, pages
      self.date = Time.local(year, month)
      config.h['date'] = self.date
    end
  end

  ##
  # Generates a virtual page with yearly index pages.
  # You must subclass and provide a content method.

  class YearlyPage < GeneratedIndex
    def self.generate_all site, dir, pages
      pages.find_all(&:dated?).group_by { |page|
        page.date.year
      }.each do |year, subpages|
        path = "#{dir}/%4d/index.html.md.erb" % [year]
        self.new site, path, subpages, year
      end
    end

    def initialize site, path, pages, year
      super site, path, pages
      self.date = Time.local(year)
      config.h['date'] = self.date
    end
  end
end

require "yaml"

require "zenweb/extensions"

module Zenweb
  ##
  # Provides a hierarchical dictionary made of yaml fragments and files.
  #
  # Any given page in zenweb can start with a YAML header. All files
  # named "_config.yml" up the directory tree to the top are
  # considered parents of that config. Access a config like you would
  # any hash and you get inherited values.

  class Config
    include Rake::DSL

    ##
    # The shared site instance

    attr_reader :site

    ##
    # The path to this config's file

    attr_reader :path

    ##
    # The parent to this config or nil if we're at the top level _config.yml.

    attr_reader :parent

    ##
    # Create a new Config for site at a given path.

    def initialize site, path
      @site, @path, @parent = site, path, nil

      File.each_parent path, "_config.yml" do |config|
        next unless File.file? config
        @parent = site.configs[config] unless config == path
        break if @parent
      end

      @parent ||= Config::Null
    end

    ##
    # Access value at +k+. The value can be inherited from the parent configs.

    def [] k
      h.key?(k.to_s) ? h[k.to_s] : parent[k]
    end

    def key? k
      h.key?(k.to_s) or parent.key?(k)
    end

    UTF_BOM = "\xEF\xBB\xBF".b

    ##
    # Splits a file and returns the yaml header and body, as applicable.
    #
    #   split("_config.yml")   => [config, nil]
    #   split("blah.txt")      => [nil,    content]
    #   split("index.html.md") => [config, content]

    def self.split path
      body, yaml_file = nil, false
      if String === path and File.file? path
        body = File.binread path

        raise ArgumentError, "UTF BOM not supported: #{path}" if
          body.start_with? UTF_BOM

        yaml_file = File.extname(path) == ".yml"

        body.force_encoding Encoding::UTF_8
      else
        body = path.content
      end

      if yaml_file then
        [body, nil]
      elsif body.start_with? "---" then
        body.split(/^\.\.\.$/, 2)
      else
        [nil, body.valid_encoding? ? body : body.force_encoding('ASCII-8BIT')]
      end

    end

    def h # :nodoc:
      @h ||= begin
               thing = File.file?(path) ? path : site.pages[path]
               config, _ = self.class.split thing
               maybe_load_yaml(config) || {}
             end
    rescue => e
      warn "#{self.path}: #{e}"
      raise
    end

    def maybe_load_yaml config
      if config then
        if YAML.respond_to? :safe_load_file then
          YAML.safe_load config, permitted_classes: [Time]
        else
          YAML.load config
        end
      end
    end

    def inspect # :nodoc:
      if Rake.application.options.trace then
        hash = h.sort.map { |k,v| "#{k.inspect} => #{v.inspect}" }.join ", "
        "Config[#{path.inspect}, #{parent.inspect}, #{hash}]"
      else
        "Config[#{path.inspect}, #{parent.inspect}]"
      end
    end

    def to_s # :nodoc:
      "Config[#{path.inspect}]"
    end

    ##
    # Wire up this config to the rest of the rake dependencies.

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self.path

      file self.path => self.parent.path if self.parent.path # HACK

      self.parent.wire
    end
  end # class Config

  # :stopdoc:
  Config::Null = Class.new Config do
    def [] k;                    end
    def key? k;                  end
    def initialize;              end
    def inspect; "Config::Null"; end
    def wire;                    end
  end.new
  # :startdoc:
end

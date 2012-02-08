require "yaml"

gem "rake"
require "rake"

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
      h[k.to_s] or parent[k]
    end

    ##
    # Splits a file and returns the yaml header and body, as applicable.
    #
    #   split("_config.yml")   => [config, nil]
    #   split("blah.txt")      => [nil,    content]
    #   split("index.html.md") => [config, content]

    def self.split path
      body = File.binread path

      raise ArgumentError, "UTF BOM not supported: #{path}" if
        body.start_with? "\xEF\xBB\xBF"

      yaml_file = File.extname(path) == ".yml"

      if yaml_file or body.start_with? "---" then
        body.force_encoding "utf-8" if File::RUBY19

        if yaml_file then
          [body, nil]
        else
          body.split(/^\.\.\.$/, 2)
        end
      else
        [nil, body]
      end
    end

    def h # :nodoc:
      @h ||= begin
               config, _ = self.class.split path
               config && YAML.load(config) || {}
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
    def initialize;              end
    def inspect; "Config::Null"; end
    def wire;                    end
  end.new
  # :startdoc:
end

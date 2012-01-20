require "yaml"

gem "rake"
require "rake"

module Zenweb
  class Config
    include Rake::DSL

    attr_reader :site, :path, :parent

    def initialize site, path
      @site, @path, @parent = site, path, nil

      File.each_parent path, "_config.yml" do |config|
        next unless File.file? config
        @parent = site.configs[config] unless config == path
        break if @parent
      end

      @parent ||= Config::Null
    end

    def [] k
      h[k] or parent[k]
    end

    def h
      @h ||= YAML.load(File.read path) || {}
    end

    def inspect
      if Rake.application.options.trace then
        "Config[#{path.inspect}, #{parent.inspect}, #{h.inspect[1..-2]}]"
      else
        "Config[#{path.inspect}, #{parent.inspect}]"
      end
    end

    def to_s
      "Config[#{path.inspect}]"
    end

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self.path

      file self.path => self.parent.path if self.parent.path # HACK

      self.parent.wire
    end
  end # class Config

  Config::Null = Class.new Config do
    def [] k;                    end
    def initialize;              end
    def inspect; "Config::Null"; end
    def wire;                    end
  end.new
end


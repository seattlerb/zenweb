module Zenweb
  class Config
    include Rake::DSL

    attr_reader :site, :path, :parent

    def initialize site, path
      @site, @path, @parent = site, path, nil
      site.configs[path] = self

      File.each_parent path, "_config.yml" do |config|
        next unless File.file? config
        @parent = site.configs[config] unless config == path
        break if @parent
      end

      @parent ||= Config::Null
    end

    def h
      @h ||= YAML.load(File.read path) || {}
    end

    def [] k
      h[k] or parent[k]
    end

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self => self.parent
      self.parent.wire
    end

    def inspect
      if Rake.application.options.trace then
        "Config[#{path.inspect}, #{parent.inspect}, #{h.inspect[1..-2]}]"
      else
        "Config[#{path.inspect}, #{parent.inspect}]"
      end
    end

    alias :to_s :path
  end # class Config

  Config::Null = Class.new Config do
    def initialize; end
    def [] k;       end
    def inspect; "Config::Null"; end

    def wire # HACK? honestly... I don't know. blame rake
      @wired ||= false # HACK
      return if @wired
      @wired = true

      task ""
    end
  end.new
end


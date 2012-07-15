class Zenweb::Renderer

  @@extensions = {}

  def self.renders *extensions
    extensions.each do |extension|
      @@extensions[extension.downcase] = self
    end
  end

  def self.renderers
    @@extensions
  end

  def self.process underlying_page, type, page, content
    r = @@extensions[type.downcase].new
    r.underlying_page = underlying_page
    r.process page, content
  end

  attr_accessor :underlying_page

  def process page, content
    # Subclasses must implement
  end

  def method_missing method, *args
    @underlying_page.send method, *args
  end

end

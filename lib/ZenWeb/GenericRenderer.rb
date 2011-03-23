$TESTING = FALSE unless defined? $TESTING

=begin

= Class GenericRenderer

A GenericRenderer provides an interface for all renderers. It renders
nothing itself.

=== Methods

=end

class GenericRenderer

=begin

--- GenericRenderer.new(document)

    Instantiates a generic renderer with a reference to
    ((|document|)), it\'s website and sitemap.

=end

  # REFACTOR: do not take a document at all
  def initialize(document)
    @document = document
    @website = @document.website
    @sitemap = @website.sitemap
    @result = []
  end

=begin

--- GenericRenderer#push(obj)

    Pushes a string representation of ((|obj|)) onto the result
    array. If ((|obj|)) is an array, it iterates each item and pushes
    them (recursively). If it is not an array, it pushes (({obj.to_s})).

=end

  def push(obj)
    if obj.is_a?(Array) then
      stuff = obj.flatten
      @result.push(*stuff) unless stuff.empty?
    else
      if false then
        @result.push(obj.to_s)
      else
        @result.push(obj)
      end       
    end
  end

=begin

--- GenericRenderer#unshift(obj)

    Same as ((<GenericRenderer#push>)) but prepends instead of appends.

=end

  def unshift(obj)
    if obj.is_a?(Array) then
      obj.reverse.each { | item |
        self.unshift(item)
      }
    else
      @result.unshift(obj.to_s)
    end

  end

  # DOC GenericRenderer#result
  def result(clear=true)
    result = @result.join('')
    @result = [] if clear
    return result
  end

=begin

--- GenericRenderer#render(content)

    Renders the content. Does nothing in GenericRenderer, but is
    expected to be overridden by subclasses. ((|content|)) is an array
    of strings and render must return an array of strings.

    NEW: the argument and result are now a single string!

=end

  # REFACTOR: pass in content and document to render
  def render(content)
    return content
  end

  def each_paragraph(content)
    content.scan(/.+?(?:#{$/}#{$/}+|\Z)/m) do |block|
      $stderr.puts "BLOCK = #{block.inspect}" if $DEBUG
      yield(block)
    end
  end

  def each_paragraph_matching(content, pattern)
    $stderr.puts "CONTENT = #{content.inspect}" if $DEBUG
    self.each_paragraph(content) do |block|
      $stderr.puts "PARAGRAPH = #{block.inspect}" if $DEBUG
      if block =~ pattern then
        yield(block)
      else
        push block
      end
    end
  end

  def scan_region(content, region_start, region_end)
    matching = false
    content.scan(/.*#{$/}?/) do |l|
      # TODO: detect region_end w/o start and freak
      # TODO: detect nesting and freak
      if l =~ region_start then
        matching = true
        $stderr.puts :START, l.inspect if $DEBUG
        yield(l, :START)
        matching = false if l =~ region_end
      elsif l =~ region_end then
        matching = false
        $stderr.puts :END, l.inspect if $DEBUG
        yield(l, :END)
      elsif matching then
        $stderr.puts :MIDDLE, l.inspect if $DEBUG
        yield(l, :MIDDLE)
      else
        $stderr.puts :IGNORED, l.inspect if $DEBUG
        push l
      end
    end
  end

end


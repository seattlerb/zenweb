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

  # REFACTOR: content and metadata on render
  def render(content)
    return content
  end

  def each_paragraph(content)
    content.split($PARAGRAPH_RE).each do | p |
      yield(p)
      push("\n\n")
    end
  end

  def each_paragraph_matching(content, pattern)
    self.each_paragraph(content) do |p|
      if p =~ pattern then
        yield(p)
      else
	push p
      end
    end
  end

  def scan_region(content, region_start, region_end)
    matching = false
    content.split($/).each do |p|
      # TODO: detect region_end w/o start and freak
      # TODO: detect nesting and freak
      if p =~ region_start then
        matching = true
        yield(p, :START)
        matching = false if p =~ region_end
      elsif p =~ region_end then
        matching = false
        yield(p, :END)
      elsif matching then
        yield(p, :MIDDLE)
      else
        push p + "\n"
      end
    end
  end

end


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
      obj.each { | item |
	self.push(item)
      }
    else
      @result.push(obj.to_s)
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
  def result
    return @result.join('')
  end

=begin

--- GenericRenderer#render(content)

    Renders the content. Does nothing in GenericRenderer, but is
    expected to be overridden by subclasses. ((|content|)) is an array
    of strings and render must return an array of strings.

    NEW: the argument and result are now a single string!

=end

  def render(content)
    return content
  end

end


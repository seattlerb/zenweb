require 'ZenWeb/GenericRenderer'

=begin

= Class CompositeRenderer

Allows multiple renderers to be plugged into a single renderer.

=== Methods

=end

class CompositeRenderer < GenericRenderer

=begin

--- CompositeRenderer#new(document)

    Creates a new CompositeRenderer.

=end

  def initialize(document)
    super(document)
    @renderers = []
  end

  def addRenderer(renderer)
    @renderers.push(renderer)
  end

=begin

--- CompositeRenderer#render(content)

    Renders by running all of the renderers in sequence.

=end

  def render(content)
    @renderers.each { | renderer |
      content = renderer.render(content)
    }
    return content
  end

end


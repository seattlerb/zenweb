require 'ZenWeb/CompositeRenderer'
require 'ZenWeb/SubpageRenderer'
require 'ZenWeb/MetadataRenderer'
require 'ZenWeb/TextToHtmlRenderer'
require 'ZenWeb/HtmlTemplateRenderer'
require 'ZenWeb/FooterRenderer'

=begin

= Class StandardRenderer

Creates a fairly standard webpage using several different renderers.

=== Methods

=end

class StandardRenderer < CompositeRenderer

=begin

--- StandardRenderer#new(document)

    Creates a new StandardRenderer.

=end

  def initialize(document)
    super(document)

    self.addRenderer(SubpageRenderer.new(document))
    self.addRenderer(MetadataRenderer.new(document))
    self.addRenderer(TextToHtmlRenderer.new(document))
    self.addRenderer(HtmlTemplateRenderer.new(document))
    self.addRenderer(FooterRenderer.new(document))
  end

end


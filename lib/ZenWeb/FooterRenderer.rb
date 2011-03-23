require 'ZenWeb/GenericRenderer'

=begin

= Class FooterRenderer

Inserts a footer based on metadata.

=== Methods

=end

class FooterRenderer < GenericRenderer

=begin

--- FooterRenderer#render(content)

    Adds a footer if the ((|footer|)) metadata item exists. If the
    document contains a BODY close HTML tag, then the footer
    immediately precedes it, otherwise it is simply at the bottom.

=end

  def render(content)

    footer = @document['footer'] || nil

    if footer then
      content.sub!(/(<\/BODY>|\z)/i) {
        footer + $1
      }
    end

    return content
  end
end


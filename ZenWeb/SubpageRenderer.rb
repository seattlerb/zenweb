require 'ZenWeb/GenericRenderer'

=begin

= Class SubpageRenderer

Generates a list of known subpages in a format compatible with
TextToHtmlRenderer.

=== Methods

=end

class SubpageRenderer < GenericRenderer

=begin

     --- SubpageRenderer#render(content)

     Renders a list of known subpages in a format compatible with
     TextToHtmlRenderer. Adds the list to the end of the content.

=end

  def render(content)
    subpages = @document.subpages.clone
    if (subpages.length > 0) then
      push("\n\n")
      push("** Subpages:\n\n")
      subpages.each_index { | index |
	url      = subpages[index]
	doc      = @website[url]
	title    = doc.fulltitle

	push("+ <A HREF=\"#{url}\">#{title}</A>\n")
      }
      push("\n")
    end

    return content + self.result
  end
end


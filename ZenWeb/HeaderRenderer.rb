require 'ZenWeb/GenericRenderer'

=begin

= Class HeaderRenderer

Inserts a header based on metadata.

=== Methods

=end

class HeaderRenderer < GenericRenderer

=begin

--- HeaderRenderer#render(content)

    Adds a header if the ((|header|)) metadata item exists. If the
    document contains a BODY HTML tag, then the header immediately
    follows it, otherwise it is simply at the top.

=end

  def render(content)

    header = @document['header'] || nil

    if header then
      placed = false

      content.each { | line |

	push(line)

	if (line =~ /<BODY/i) then
	  push(header)
	  placed = true
	end
      }

      unless placed then
	unshift(header) unless placed
      end
    else
      push(content)
    end

    return self.result
  end
end


require 'ZenWeb/GenericRenderer'

=begin

= Class HtmlRenderer

Abstract superclass that provides common functionality for those
renderers that produce HTML.

=== Methods

=end

class HtmlRenderer < GenericRenderer

=begin

--- HtmlRenderer#render(content)

    Raises an exception. This is subclass responsibility as this is an
    abstract class.

=end

  def render(content)
    raise "Subclass Responsibility"
  end

=begin

--- HtmlRenderer#array2html

    Converts an array (of arrays, potentially) into an unordered list.

=end

  def array2html(list, indent=0)
    result = ""

    indent1 = "  " * indent
    indent2 = "  " * (indent + 1)

    result += (indent1 + "<UL>\n")
    list.each { | l |
      if (l.is_a?(Array)) then
	result += self.array2html(l, indent+1)
      else
	result += (indent2 + "<LI>" + l.to_s + "</LI>\n")
      end
    }
    result += (indent1 + "</UL>\n")

    return result
  end

  def hash2html(hash, order)
    result = ""

    if (hash) then
      result += "<DL>\n"
      order.each { | key |
	val = hash[key] or raise "Key '#{key}' is missing!"
	result += "  <DT>#{key}</DT>\n"
	result += "  <DD>#{val}</DD>\n\n"
      }
      result += "</DL>\n"
    else
      result = "not a hash"
    end

    return result
  end

end


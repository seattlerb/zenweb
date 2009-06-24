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

  def array2html(list, ordered=false, indent=0)
    result = []

    indent1 = "  " * indent
    indent2 = "  " * (indent + 1)

    tag = ordered ? "OL" : "UL"

    result << "#{indent1}<#{tag}>\n"
    list.each { | l |
      if (l.is_a?(Array)) then
        x = result.pop
        result.push "\n"
        result.push self.array2html(l, ordered, indent+2)
        result.push indent2 unless x =~ /^\s+/
        result.push x
      else
	result.push(indent2, "<LI>", l.to_s, "</LI>\n")
      end
    }
    result << "#{indent1}</#{tag}>\n"

    return result.join
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


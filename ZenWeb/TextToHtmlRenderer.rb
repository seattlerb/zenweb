require 'ZenWeb/HtmlRenderer'

=begin

= Class TextToHtmlRenderer

Converts a fairly plain text format into styled HTML.

=== Methods

=end

class TextToHtmlRenderer < HtmlRenderer

=begin

--- TextToHtmlRenderer#render(content)

    Converts a simple plaintext format into formatted HTML. Includes
    paragraphing, embedded variables, lists, rules, preformatted
    blocks, and embedded HTML. See the demo pages for a complete
    description on how to use this.

=end

  def render(content)

    text = content.join('')
    content = text.split(/#{$/}#{$/}+/)

    content.each { | p |

      # massage a little
      p = p.sub(/^#{$/}+/, '') # end of paragraph -> ''
      p.chomp!

      p.gsub!(/\\&/, "&amp;")
      p.gsub!(/\\</, "&lt;")
      p.gsub!(/\\>/, "&gt;")
      p.gsub!(/\\\"/, "&quot;")

      p.gsub!(/\\\{/, "{")
      p.gsub!(/\\:/, "&#58;")

      # WARN Not sure if I want to do this or not... thinking about it.
      # p.gsub!(/\\(.)/) { | c | "&##{$1.unpack('c').to_s};" }

      # url substitutions
      p.gsub!(/([^=\"])((http|ftp|mailto):(\S+))/) {
	pre = $1
	url = $2
	text = $4

	text.gsub!(/\//, " ")
	text.strip!
	text.gsub!(/ /, " /")

	"#{pre}<A HREF=\"#{url}\">#{text}</A>"
      }

      if (p =~ /^(\*\*+)\s*(.*)$/) then
	level = $1.length
	push("<H#{level}>#{$2}</H#{level}>\n\n")
      elsif (p =~ /^---+$/) then
	push("<HR SIZE=\"1\" NOSHADE>\n\n")
      elsif (p =~ /^===+$/) then
	push("<HR SIZE=\"2\" NOSHADE>\n\n")
      elsif (p =~ /^%[=-]/) then # FIX: needs to maintain order
	hash = @document.createHash(p)

	if (hash) then
	  push(self.hash2html(hash) + "\n")
	end
      elsif (p =~ /^\t*\+/) then
	p.gsub!(/^(\t*)\+\s*(.*)$/) { $1 + $2 }

	list = @document.createList(p)

	if (list) then
	  push(self.array2html(list) + "\n")
	end
      elsif (p =~ /^\ \ / and p !~ /^[^\ ]/) then
	p.gsub!(/^\ \ /, '')
	push("<PRE>" + p + "</PRE>\n\n")
      else
	push("<P>" + p + "</P>\n\n")
      end
    }

    # FIX: xmp makes this slow
    # put it back into line-by-line format
    # I use scan instead of split so I can keep the EOLs.
    @result = @result.join("\n").scan(/^.*[\n\r]+/)

    return @result

  end

end


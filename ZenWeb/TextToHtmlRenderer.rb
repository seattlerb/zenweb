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

    text = content.split($PARAGRAPH_RE)

    text.each { | p |

      # massage a little
      p = p.sub($PARAGRAPH_END_RE, '')
      p.chomp!

      p.gsub!(/\\&/, "&amp;")
      p.gsub!(/\\</, "&lt;")
      p.gsub!(/\\>/, "&gt;")
      p.gsub!(/\\\"/, "&quot;")

      p.gsub!(/\\\{/, "{")
      p.gsub!(/\\:/, "&#58;")

      # WARN Not sure if I want to do this or not... thinking about it.
      # p.gsub!(/\\(.)/) { | c | sprintf("&#%04X#;", $1[0]) }

      # url substitutions
      p.gsub!(/([^=\"])((http|ftp|mailto):(\S+))/) {
	pre = $1
	url = $2
	txt = $4

	txt.gsub!(/\//, " ")
	txt.strip!
	txt.gsub!(/ /, " /")

	"#{pre}<A HREF=\"#{url}\">#{txt}</A>"
      }

      if (p =~ /^(\*\*+)\s*(.*)$/) then
	level = $1.length
	push("<H#{level}>#{$2}</H#{level}>\n\n")
      elsif (p =~ /^---+$/) then
	push("<HR SIZE=\"1\" NOSHADE>\n\n")
      elsif (p =~ /^===+$/) then
	push("<HR SIZE=\"2\" NOSHADE>\n\n")
      elsif (p =~ /^%[=-]/) then # FIX: needs to maintain order
	hash, order = self.createHash(p)

	if (hash) then
	  push(self.hash2html(hash, order) + "\n")
	end
      elsif (p =~ /^\t*([\+=])/) then
        ordered = $1 == "="
	list = self.createList(p)

	if (list) then
	  push(self.array2html(list, ordered))
	end
      elsif (p =~ /^\ \ / and p !~ /^[^\ ]/) then
	p.gsub!(/^\ \ /, '')
	push("<PRE>" + p + "</PRE>\n\n")
      elsif p =~ %r%^[^<]% or p =~ $INLINE_RE then
	push("<P>" + p + "</P>\n\n")
      else
	push p
      end
    }

    # TODO: need to extend: ordered lists

    # FIX: xmp makes this slow
    # put it back into line-by-line format
    # I use scan instead of split so I can keep the EOLs.
    # @result = @result.join("\n").scan(/^.*[\n\r]+/)

    return self.result

  end

=begin

--- ZenDocument#createList

    Convert a string composed of lines prefixed by plus signs into an
    array of those strings, sans plus signs. If a line is indented
    with tabs, then the lines at that indention level will become an
    array of their own, to be added to the encompassing array.

=end

  def createList(data)

    if (data.is_a?(String)) then
      # TODO: at some time we'll want to support different types of lists
      data = data.gsub(/^(\t*)([\+=])\s*(.*)$/) { type=$2; $1 + $3 }
      data = data.split($/)
    end

    min = -1
    i = 0
    len = data.size

    while (i < len)
      if (min == -1) then

	# looking for initial match:
	if (data[i] =~ /^\t(\t*.*)/) then

	  # replace w/ one less tab, and record that we have a match
	  data[i] = $1
	  min = i
	end
      else

	# found match, looking for mismatch
	if (data[i] !~ /^\t(\t*.*)/ or i == len) then

	  # found mismatch, replacing w/ sublist
	  data[min..i-1] = [ createList(data[min..i-1]) ]
	  # resetting appropriate values
	  len = data.size
	  i = min
	  min = -1
	else
	  data[i] = $1
	end
      end
      i += 1
    end

    if (i >= len - 1 and min != -1) then
      data[min..i-1] = [ createList(data[min..i-1]) ]
    end

    return data
  end

=begin

--- ZenDocument#createHash

    Convert a string composed of lines prefixed one of two delimiters
    into a hash. If the delimiter is "%-", then that string is used
    as the key to the hash. If the delimiter is "%=", then that
    string is used as the value to the hash.

=end

  def createHash(data)

    result = {}
    order = []

    if (data.is_a?(String)) then
      data = data.split($/)
    end

    key = nil
    data.each { |line|
      if (line =~ /^\s*%-\s*(.*)/) then
	key = $1
      elsif (line =~ /^\s*%=\s*(.*)/) then
	val = $1

	if (key) then
	  # WARN: maybe do something if already defined?
	  result[key] = val
	  order << key
	end

      else
	# nothing
      end
    }

    return result, order
  end

end

require 'ZenWeb/GenericRenderer'

=begin

= Class TocRenderer

This renderer generate a table-of-contents at the beginning of the
document in a format compatible with the text-to-html renderer. It
uses the header notation (** to ******) of the text-to-html renderer
to decide what goes in the TOC. It expects your document to be
formatted properly (ie, don't jump from ** to ****--just like in
English class).

=== Methods

=end

class TocRenderer < GenericRenderer

=begin

--- TocRenderer#render(content)

    Renders the TOC content.

=end

  def render(content)

    toc = [
      "** <A NAME=\"0\">Contents:</A>\n",
      "\n",
      "+ <A HREF=\"\#0\">Contents</A>\n" ]
    count = 1

    content.each { | line |
      if line =~ /^(\*\*+)\s+(.*)/ then
	header = $1
	text = $2

	text = text.sub(/:$/, '')

	level = header.length - 2

	toc.push(("\t" * level) + "+ <A HREF=\"\##{count}\">#{text}</A>\n")

	push "#{header} <A NAME=\"#{count}\">#{text}</A>\n"
	# " [<A HREF=\"\#0\">toc</A>]\n"

	count += 1
      else
	push line
      end
    }

    unshift(toc) if toc.length > 3

    return self.result
  end

end

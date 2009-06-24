require 'ZenWeb/GenericRenderer'

=begin

= Class SitemapRenderer

Converts a sitemap file into output suitable for
((<Class TextToHtmlRenderer>)).

=== Methods

=end

class SitemapRenderer < GenericRenderer

=begin

--- SitemapRenderer#render(content)

    Converts a sitemap file into output suitable for ((<Class TextToHtmlRenderer>)).

=end

  def render(content)

    # used for /~user/blah.html pages
    # basically, we need to strip off whatever the base of the sitemap is to
    # make sure we indent everything to the right level.
    base = @sitemap.url
    base = base.sub(%r%/[^/]*$%, '/')

    urls = @sitemap.doc_order.clone

    @document['subtitle'] ||= "There are #{urls.size} pages in this website."
    urls.each { | url |

      indent = url.sub(/\.html$/, "")
      indent.sub!(/#{base}/, "")
      indent.sub!(/\/index$/, "")
      indent.sub!(/^\//, "")
      indent.gsub!(/[^\/]+\//, "\t")

      if indent =~ /^(\t*).*/ then
	indent = $1
      end

      doc      = @website[url]
      title    = doc.fulltitle

      push("#{indent}+ <A HREF=\"#{url}\">#{title}</A>\n")
    }

    return self.result
  end
end


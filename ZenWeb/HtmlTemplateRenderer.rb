require 'ZenWeb/HtmlRenderer'

=begin

= Class HtmlTemplateRenderer

Generates a consistant HTML page header and footer, including a
navigation bar, title, subtitle, and appropriate META tags.

=== Methods

=end

class HtmlTemplateRenderer < HtmlRenderer

=begin

--- HtmlTemplateRenderer#render(content)

    Renders a standardized HTML header and footer. This currently also
    includes a navigation bar and a list of subpages, which will
    probably be broken out to their own renderers soon.

    Metadata variables used:

    + author
    + banner - graphic at the top of the page, usually a logo
    + bgcolor - defaults to not being defined
    + copyright
    + description
    + dtd (default: 'DTD HTML 4.0 Transitional')
    + email - used in a mailto in metadata
    + keywords
    + rating (default: 'general')
    + stylesheet
    + subtitle
    + title (default: 'Unknown Title')

=end

  def render(content)
    author      = @document['author']
    banner      = @document['banner']
    bgcolor     = @document['bgcolor']
    dtd		= @document['dtd'] || 'DTD HTML 4.0 Transitional'
    copyright   = @document['copyright']
    description = @document['description']
    email       = @document['email']
    keywords    = @document['keywords']
    rating      = @document['rating'] || 'general'
    stylesheet  = @document['stylesheet']
    subtitle    = @document['subtitle']
    title       = @document['title'] || 'Unknown Title'
    charset     = @document['charset']

    titletext   = @document.fulltitle

    # header
    push("<!DOCTYPE HTML PUBLIC \"-//W3C//#{dtd}//EN\">\n")
    push("<HTML>\n")
    push("<HEAD>\n")
    push("<TITLE>#{titletext}</TITLE>\n")

    push("<LINK REV=\"MADE\" HREF=\"#{email}\">\n") if email
    push("<LINK REL=\"STYLESHEET\" HREF=\"#{stylesheet}\" type=text/css title=\"#{stylesheet}\">\n") if stylesheet

    push("<META NAME=\"rating\" CONTENT=\"#{rating}\">\n")
    push("<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">\n")
    push("<META NAME=\"author\" CONTENT=\"#{author}\">\n") if author
    push("<META NAME=\"copyright\" CONTENT=\"#{copyright}\">\n") if copyright
    push("<META NAME=\"keywords\" CONTENT=\"#{keywords}\">\n") if keywords
    push("<META NAME=\"description\" CONTENT=\"#{description}\">\n") if description
    push("<META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=#{charset}\">") if charset

    push("</HEAD>\n")
    push("<BODY" + (bgcolor ? " BGCOLOR=\"#{bgcolor}\"" : '') + ">\n")

    self.navbar

    if banner then
      push("<IMG SRC=\"#{banner}\" BORDER=0><BR>\n")
      unless (subtitle) then
	push("<H3>#{title}</H3>\n")
      end
    else
      push("<H1>#{title}</H1>\n")
    end

    push("<H2>#{subtitle}</H2>\n") if subtitle
    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    push(content)

    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    self.navbar

    push("\n</BODY>\n</HTML>\n")

    return self.result
  end

=begin

--- HtmlTemplateRenderer#navbar

    Generates a navbar that contains a link to the sitemap, search
    page (if any), and a fake "breadcrumbs" trail which is really just
    a list of all of the parent titles up the chain to the top.

=end

  def navbar

    sep = " / "
    sitemap = @website.sitemap
    search  = @website["/Search.html"]

    push("<P>\n")

    push("<A HREF=\"#{sitemap.url}\"><STRONG>Sitemap</STRONG></A>")

    if search then
      push(" | ")
      push("<A HREF=\"#{search.url}\"><STRONG>Search</STRONG></A>")
    end

    push(" || ")

    path = []
    current = @document

    while current
      current = current.parent
      path.unshift(current) if current
    end

    path.each { | doc |
      url = doc.url
      title = doc['title']

      push("<A HREF=\"#{url}\">#{title}</A>\n")
      push(sep)
    }

    push(@document['title'])

    push("</P>\n")

    return []
  end

end


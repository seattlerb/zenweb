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
    + stylesheet - reference to a CSS file
    + style - CSS code directly (for smaller snippets)
    + subtitle
    + title (default: 'Unknown Title')
    + icbm - longitude and latitude for geourl.org
    + icbm_title - defaults to the page title

=end

  def render(content)
    author      = @document['author']
    banner      = @document['banner']
#   bgcolor     = @document['bgcolor']
    charset     = @document['charset']
    copyright   = @document['copyright']
    description = @document['description']
    dtd		= @document['dtd'] || 'DTD HTML 4.01'
    email       = @document['email']
    icbm        = @document['icbm']
    keywords    = @document['keywords']
    lang        = @document['lang'] || 'en'
    rating      = @document['rating'] || 'general'
    style       = @document['style']
    stylesheet  = @document['stylesheet']
    subtitle    = @document['subtitle']
    title       = @document.title

    icbm_title  = @document['icbm_title'] || title
    titletext   = @document.fulltitle

    # TODO: iterate over a list of metas and add them in one nicely organized block

    # header
    push([
	   "<!DOCTYPE HTML PUBLIC \"-//W3C//#{dtd}//EN\">\n",
	   "<HTML lang=\"#{lang}\">\n",
	   "<HEAD>\n",
	   "<TITLE>#{titletext}</TITLE>\n",
	   email ? "<LINK REV=\"MADE\" HREF=\"#{email}\">\n" : [],
	   stylesheet ? "<LINK REL=\"STYLESHEET\" HREF=\"#{stylesheet}\" type=\"text/css\" title=\"#{stylesheet}\">\n" : [],
	   "<META NAME=\"rating\" CONTENT=\"#{rating}\">\n",
	   "<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">\n",
	   style ? "<STYLE>\n#{style}\n</STYLE>" : [],
	   author ? "<META NAME=\"author\" CONTENT=\"#{author}\">\n" : [],
	   copyright ? "<META NAME=\"copyright\" CONTENT=\"#{copyright}\">\n" : [],
	   keywords ? "<META NAME=\"keywords\" CONTENT=\"#{keywords}\">\n" : [],
	   description ? "<META NAME=\"description\" CONTENT=\"#{description}\">\n" : [],
	   charset ? "<META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=#{charset}\">" : [],
	   icbm ? "<meta name=\"ICBM\" content=\"#{icbm}\">\n<meta name=\"DC.title\" content=\"#{icbm_title}\">\n" : [],

           "<link rel=\"up\" href=\"#{@document.parentURL}\" title=\"#{@document.parent.title}\">\n",
           "<link rel=\"contents\" href=\"#{@sitemap.url}\" title=\"#{@sitemap.title}\">\n",
           "<link rel=\"top\" href=\"#{@website.top.url}\" title=\"#{@website.top.title}\">\n",
           # TODO: add next/prev

	   "</HEAD>\n",
	   "<BODY>\n\n"
	 ])

    self.navbar(1)

    push("<DIV class=\"title\">\n")
    if banner then
      push("<IMG SRC=\"#{banner}\" BORDER=0><BR>\n")
      unless (subtitle) then
	push("<H3>#{title}</H3>\n")
      end
    else
      push("<H1>#{title}</H1>\n")
    end

    # TODO: add divs everywhere (all renderers)

    push([
	   subtitle ? "<H2>#{subtitle}</H2>\n" : [],
           "</DIV><!-- title -->\n\n",
	   "<HR>\n\n",
           "<DIV ID=\"main\">\n",
	   content,
           "</DIV><!-- main -->\n\n",
	   "<HR>\n\n",
	 ])

    self.navbar(4)

    push("\n</BODY>\n</HTML>\n")

    return self.result
  end

=begin

--- HtmlTemplateRenderer#navbar

    Generates a navbar that contains a link to the sitemap, search
    page (if any), and a fake "breadcrumbs" trail which is really just
    a list of all of the parent titles up the chain to the top.

=end

  def navbar(n)

    sep = " / "
    search  = @website["/Search.html"]

    push([
	   "<DIV class=\"sidebar\" id=\"block#{n}\">\n",
	   "<SPAN><A HREF=\"#{@sitemap.url}\">Sitemap</A>",
	   search ? " <SPAN>|</SPAN></SPAN>\n" : [],
           search ? "<SPAN><A HREF=\"#{search.url}\"><EM>Search</EM></A>" : [],
	   " <SPAN>||</SPAN></SPAN>\n",
	 ])

    path = []
    current = @document
    while current and current != current.parent do
      current = current.parent
      path.unshift(current) if current
    end

    push([
	   path.map{|doc| ["<SPAN><A HREF=\"#{doc.url}\">#{doc['title']}</A>\n", sep, "</SPAN>\n"]},
	   "<SPAN>#{@document['title']}</SPAN>\n",
	   "</DIV><!-- sidebar block#{n} -->\n\n",
	 ])

    return []
  end

end


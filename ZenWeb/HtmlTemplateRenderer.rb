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
    + dtd (default: 'DTD HTML 4.0')
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
    bgcolor     = @document['bgcolor']
    dtd		= @document['dtd'] || 'DTD HTML 4.0'
    copyright   = @document['copyright']
    description = @document['description']
    email       = @document['email']
    keywords    = @document['keywords']
    rating      = @document['rating'] || 'general'
    stylesheet  = @document['stylesheet']
    subtitle    = @document['subtitle']
    title       = @document['title'] || 'Unknown Title'
    icbm        = @document['icbm']
    icbm_title  = @document['icbm_title'] || @document['title']
    charset     = @document['charset']
    style       = @document['style']
    naked_page  = @document['naked_page']
    head_extra  = @document['head_extra'] || []

    titletext   = @document.fulltitle

    # TODO: iterate over a list of metas and add them in one nicely organized block

    if bgcolor then
      style ||= ""
      style = "body { background-color: #{bgcolor} }\n" + style
    end

    # header
    push([
	   "<!DOCTYPE HTML PUBLIC \"-//W3C//#{dtd}//EN\">\n",
	   "<HTML>\n",
	   "<HEAD>\n",
	   "<TITLE>#{titletext}</TITLE>\n",
	   email ? "<LINK REV=\"MADE\" HREF=\"#{email}\">\n" : [],
	   stylesheet ? "<LINK REL=\"STYLESHEET\" HREF=\"#{stylesheet}\" TYPE=\"text/css\" title=\"#{stylesheet}\">\n" : [],
	   "<META NAME=\"rating\" CONTENT=\"#{rating}\">\n",
	   "<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">\n",
	   style ? "<STYLE TYPE=\"text/css\">\n#{style}\n</STYLE>" : [],
	   author ? "<META NAME=\"author\" CONTENT=\"#{author}\">\n" : [],
	   copyright ? "<META NAME=\"copyright\" CONTENT=\"#{copyright}\">\n" : [],
	   keywords ? "<META NAME=\"keywords\" CONTENT=\"#{keywords}\">\n" : [],
	   description ? "<META NAME=\"description\" CONTENT=\"#{description}\">\n" : [],
	   charset ? "<META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=#{charset}\">" : [],
	   icbm ? "<meta name=\"ICBM\" content=\"#{icbm}\">\n<meta name=\"DC.title\" content=\"#{icbm_title}\">" : [],

           "<link rel=\"up\" href=\"#{@document.parentURL}\" title=\"#{@document.parent.title}\">\n",
           "<link rel=\"contents\" href=\"#{@sitemap.url}\" title=\"#{@sitemap.title}\">\n",
           "<link rel=\"top\" href=\"#{@website.top.url}\" title=\"#{@website.top.title}\">\n",

          head_extra.join("\n"),

	   "</HEAD>\n",
	   "<BODY>\n",
	 ])

    unless naked_page then
      self.navbar

      if banner then
        push("<H1><IMG SRC=\"#{banner}\" ALT=\"#{File.basename banner}\"></H1>\n")
        unless (subtitle) then
          push("<H2>#{title}</H2>\n")
        end
      else
        push("<H1>#{title}</H1>\n")
      end
    
      push([
            subtitle ? "<H2>#{subtitle}</H2>\n" : [],
            "<HR CLASS=\"thick\">\n\n",
           ])
    end

    push content

    unless naked_page then
      push([
            "<HR CLASS=\"thick\">\n\n",
           ])

      self.navbar
    end
    
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
    search  = @website["/Search.html"]

    push([
	   "<P class=\"navbar\">\n",
	   "<A HREF=\"#{@sitemap.url}\">Sitemap</A>",
	   search ? " | <A HREF=\"#{search.url}\"><EM>Search</EM></A>" : [],
	   " || ",
	 ])

    path = []
    current = @document
    while current and current != current.parent do
      current = current.parent
      path.unshift(current) if current
    end

    push([
	   path.map{|doc| ["<A HREF=\"#{doc.url}\">#{doc['title']}</A>\n", sep]},
	   @document['title'],
	   "</P>\n",
	 ])

    return []
  end

end


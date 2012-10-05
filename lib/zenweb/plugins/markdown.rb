class Zenweb::MarkdownPlugin < Zenweb::Renderer
  KRAMDOWN_CONFIG = { # :nodoc:
    :toc_levels    => '2..4',

    :coderay_wrap               => :div,
    :coderay_line_numbers       => :table,
    :coderay_tab_width          => 4,
    :coderay_css                => :class,
    # TODO: turn off smart quotes
  }

  renders 'md'

  def process page, content
    render_md page, content
  end

  ##
  # Render markdown page content using kramdown.

  def render_md page, content
    markdown(content || self.body) # HACK
  end

  ##
  # Render markdown content.
  #
  # I cheated and added some additional gsubs. I prefer "``` lang" so
  # that works now.

  def markdown content
    require "kramdown"

    content = content.
      gsub(/^``` *(\w+)/) { "{:lang=\"#$1\"}\n~~~" }.
      gsub(/^```/, '~~~')

    Kramdown::Document.new(content, KRAMDOWN_CONFIG).to_html
  end

  ############################################################
  # Helper Methods:

  ##
  # Returns a markdown formatted sitemap for the given pages or the
  # current page's subpages. This intelligently composes a sitemap
  # whether the pages are ordered (dated) or not or a combination of
  # the two.

  def sitemap pages = nil, indent = 0
    pages ||= self.subpages
    dated, regular = pages.partition(&:dated?)

    bonus   = 0
    prev    = nil
    regular = regular
    subpages =
      regular.sort_by { |p| p.url } +
      dated.sort_by   { |p| [-p.date.to_i, p.url] }

    subpages.map { |page|
      x = []

      if page.dated? then
        bonus = 1
        fmt ||= page.config["date_fmt"] || "%Y-%m" # REFACTOR: yuck
        curr = page.date.strftime fmt
        if prev != curr then
          x << "#{"  " * (indent)}* #{curr}:"
          prev = curr
        end
      end

      x << "#{"  " * (indent+bonus)}* [#{page.title}](#{page.clean_url})"
      x += [sitemap(page.subpages, indent+bonus+1)] unless page.subpages.empty?
      x
    }.flatten.join "\n"
  end

  ##
  # Convenience function to return a markdown TOC.

  def toc
    "* \n{:toc}\n"
  end

  ##
  # Return a kramdown block-tag to add attributes to the following (or
  # preceding... kramdown is a bit crazy) block. Attributes can either
  # be a simple name or a hash of key/value pairs.

  def attr h_or_name
    h_or_name = h_or_name.map { |k,v| "#{k}=\"#{v}\"" }.join " " if
      Hash === h_or_name

    "{:#{h_or_name}}"
  end

  ##
  # Return a kramdown block-tag for a CSS class.

  def css_class name
    attr ".#{name}"
  end

  ##
  # Return a kramdown block-tag for a CSS ID.

  def css_id name
    attr "##{name}"
  end

  ##
  # Return a markdown-formatted link for a given url and title.

  def link(url, title) # :nodoc:
    "[#{title}](#{url})"
  end

  ##
  # Return a markdown-formatted image for a given url and an optional alt.

  def image url, alt=url
    "![#{alt}](#{url})"
  end
end # markdown


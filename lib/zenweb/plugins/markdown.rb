class Zenweb::Page
  KRAMDOWN_CONFIG = { # :nodoc:
    :toc_levels    => '2..4',

    :entity_output => :symbolic,

    :coderay_wrap               => :div,
    :coderay_line_numbers       => :table,
    :coderay_tab_width          => 4,
    :coderay_css                => :class,
  }

  ##
  # Render markdown page content using kramdown.

  def render_md page, content
    markdown(content || self.body) # HACK
  end

  def extend_md
    extend Zenweb::Page::MarkdownHelpers
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

    Kramdown::Document.new(content, KRAMDOWN_CONFIG.dup).to_html
  end

  module MarkdownHelpers
    ##
    # Returns a markdown formatted sitemap for the given pages or the
    # current page's subpages. This intelligently composes a sitemap
    # whether the pages are ordered (dated) or not or a combination of
    # the two.

    def sitemap pages = nil
      pages ||= self.all_subpages

      pages.deep_each.chunk { |n, p| n }.map { |depth, a|
        level = (depth-1)/2
        dated, normal = a.map(&:last).partition(&:dated?)

        normal = normal.sort_by(&:url).map { |p| page_sitemap_url p, level }

        dated = dated_map(dated) { |month, ps2|
          date_sorted_map(ps2) { |p|
            page_sitemap_url p, level + 1
          }.unshift "#{"  " * (level)}* #{month}:"
        }

        normal + dated
      }.join "\n"
    end

    def page_sitemap_url page, depth # :nodoc:
      "#{"  " * (depth)}* [#{page.title}](#{page.clean_url})"
    end

    def date_sorted_map a, &b # :nodoc:
      a.sort_by { |p| [-p.date.to_i, p.url] }.map(&b)
    end

    def dated_map a, &b # :nodoc:
      a.group_by(&:date_str).sort.reverse.map(&b)
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
  end
end # markdown

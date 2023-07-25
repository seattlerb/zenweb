class Zenweb::Page
  KRAMDOWN_CONFIG = { # :nodoc:
    :toc_levels    => 2..4,
    :entity_output => :symbolic,
    :hard_wrap     => false,
    :input         => "GFM",
    :gfm_quirks    => "no_auto_typographic",

    :syntax_highlighter => :coderay,
    :syntax_highlighter_opts => {
      :wrap         => :div,
      :line_numbers => :table,
      :tab_width    => 4,
      :css          => :class,
    },
  }

  ##
  # Render markdown page content using kramdown.

  def render_md page, content
    no_line_numbers = page.config["no_line_numbers"]
    markdown(content || self.body, no_line_numbers)
  end

  def extend_md
    extend Zenweb::Page::MarkdownHelpers
  end

  ##
  # Render markdown content.
  #
  # I cheated and added some additional gsubs. I prefer "``` lang" so
  # that works now.

  def markdown content, no_line_numbers = false
    require "kramdown"
    require "kramdown-parser-gfm"
    require "kramdown-syntax-coderay"
    require "coderay/zenweb_extensions"

    config = KRAMDOWN_CONFIG.dup
    config[:coderay_line_numbers] = nil if no_line_numbers

    Kramdown::Document.new(content, config).to_html
  end

  module MarkdownHelpers
    ##
    # Returns a markdown formatted sitemap for the given pages or the
    # current page's subpages. This intelligently composes a sitemap
    # whether the pages are ordered (dated) or not or a combination of
    # the two.

    def sitemap title_dated = true, demote = 0
      self.all_subpages_by_level(true).chunk { |n, p| n }.map { |level, a|
        level -= demote

        level = 0 if level < 0

        dated, normal = a.map(&:last).reject(&:no_index?).partition(&:dated?)

        normal = normal.sort_by { |p| p.url.downcase }.map { |p| page_sitemap_url p, level }

        dated = dated_map(dated) { |month, ps2|
          x = date_sorted_map(ps2) { |p|
            page_sitemap_url p, level + (title_dated ? 1 : 0)
          }
          x.unshift "#{"  " * level}* #{month}:" if title_dated
          x
        }

        normal + dated
      }.join "\n"
    end

    def page_url page
      "[#{page.title}](#{page.clean_url})"
    end

    module_function :page_url

    def page_sitemap_url page, depth # :nodoc:
      "#{"  " * (depth)}* #{page_url page}"
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

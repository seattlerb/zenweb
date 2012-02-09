class Zenweb::Page
  KRAMDOWN_CONFIG = { # :nodoc:
    :toc_levels    => '2..4',

    :coderay_wrap               => :div,
    :coderay_line_numbers       => :table,
    :coderay_tab_width          => 4,
    :coderay_css                => :class,
    # TODO: turn off smart quotes
  }

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

  def dated_sitemap index, group = :ym, stamp = :date
    raise "removed. Use sitemap."
  end

  def sitemap index, indent=0
    index.map { |page|
      x = ["#{"  " * indent}* [#{page.title}](#{page.clean_url})"]
      unless page.subpages.empty? then
        x += [sitemap(page.subpages, indent+1)]
      end
      x
    }.flatten.join "\n"
  end

  ##
  # Convenience function to return a markdown TOC.

  def toc
    "* \n{:toc}\n"
  end

  ##
  # This is just here during the transition of my site. I'll nuke it soon.

  def link(url, title) # :nodoc:
    warn "link called from #{self.inspect}"
    "[#{title}](#{url})"
  end

  ##
  # This is just here during the transition of my site. I'll nuke it soon.

  def img(*) # :nodoc:
    raise "no!"
  end
end # markdown


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
    index -= [self]

    olddate = nil

    index.map { |post|
      extra = "{:.day}\n## #{ olddate = post.date.send group }\n\n" if
        olddate != post.date.send(group)
      "#{extra}* [#{post.date.send stamp} ~ #{post.title}](#{post.url})"
    }.join "\n"
  end

  def sitemap index
    dirs = Hash.new { |h,k| h[k] = [] }

    sorted = index.sort_by(&:clean_url)

    sorted.each do |page|
      # HACK: should use date_fmt... but ugh
      dir = File.dirname page.url.sub(%r%\d\d\d\d/\d\d/\d\d/%, "").
        sub(%r%\d\d\d\d/\d\d/%, "")

      dirs[dir] << page
    end

    original = [self.clean_url.sub(/^\//, '').split(/\//).length, 0].max

    dirs.sort.map { |(dir, pages)|
      length = dir[1..-1].split(/\//).length
      pages.map { |page|
        bonus = 0
        bonus = length > 0 && page.url =~ /index.html/ ? -1 : 0
        indent = "  " * (length+bonus-original)

        "#{indent}* [#{page.title}](#{page.url})"
      }
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


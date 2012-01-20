class Zenweb::Page
  KRAMDOWN_CONFIG = { # :nodoc:
    :auto_ids      => true,
    :footnote_nr   => 1,
    :entity_output => 'as_char',
    :toc_levels    => '1..6',

    :coderay_wrap               => 'div',
    :coderay_line_numbers       => 'inline',
    :coderay_line_number_start  => 1,
    :coderay_tab_width          => 4,
    :coderay_bold_every         => 10,
    :coderay_css                => 'class',
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
end # markdown


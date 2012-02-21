class Zenweb::Page
  ##
  # Render a page's erb and return the result

  def render_erb page, content
    erb body, self, binding
  end

  ##
  # Render erb in +content+ for +source+ with +binding.
  #
  # Personally, I find erb's delimiters a bit annoying, so for now,
  # I've added additional gsub's to the content to make it a bit more
  # palatable.
  #
  #     {{ ... }} becomes <%= ... %>
  #     {% ... %} becomes <%  ... %>
  #
  # Unfortunately, those are the delimiters from liquid, so if someone
  # goes and makes a liquid plugin it could clash. But why you'd have
  # liquid and erb on the same file is beyond me... so it prolly won't
  # become a legitimate issue.

  def erb content, source, binding = TOPLEVEL_BINDING
    require 'erb'
    extend ERB::Util

    unless defined? @erb then
      content = content.
        gsub(/\{\{/, "<%=").
        gsub(/\}\}/, "%>").
        gsub(/\{%/,  "<%").
        gsub(/%\}/,  "%>").
        gsub(/\\([{}%])/, '\1')

      @erb = ERB.new(content)
    end

    @erb.filename = source.inspect
    @erb.result binding
  end
end # erb


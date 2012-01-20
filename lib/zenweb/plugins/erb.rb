class Zenweb::Page
  ##
  # Render a page's erb and return the result

  def render_erb page, content
    body = self.body

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

    content = content.
      gsub(/\{\{/, "<%=").
      gsub(/\}\}/, "%>").
      gsub(/\{%/, "<%").
      gsub(/%\}/, "%>")

    begin
      erb = ERB.new(content)
      erb.filename = source.inspect
      erb.result binding
    rescue SyntaxError => e
      $stderr.puts "SYNTAX ERROR! #{self.inspect}: #{e}"
      $stderr.puts
      $stderr.puts content
      $stderr.puts
      raise e
    rescue RuntimeError => e
      $stderr.puts "ERROR! #{self.inspect}: #{e}"
      $stderr.puts e.backtrace.join("\n")
      raise e
    end
  end
end # erb


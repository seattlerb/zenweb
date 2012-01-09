class Zenweb::Page
  def render_erb page, content
    body = self.body

    erb body, self, binding
  end

  def erb content, source, binding = TOPLEVEL_BINDING
    require 'erb'

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


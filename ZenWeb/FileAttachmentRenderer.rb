# this is a simple template. Globally replace FileAttachment with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'

=begin

= Class FileAttachmentRenderer

Finds content between <file name="name">...</file> tags. Writes the
content to a file of the given name and includes a link to the file.

=== Methods

=end

class FileAttachmentRenderer < GenericRenderer

=begin

     --- FileAttachmentRenderer#render(content)

     YYY

=end

  def render(content)

    file_content = []
    name = nil
    self.scan_region(content, /<file\s+name\s*=\s*\"([\w\.-]+)\"\s*>/i, /<\/file>/i) do |line, context|
      case context
      when :START then
        name = $1 if line =~ /name\s*=\s*\"([\w\.-]+)\"/i
      when :END then
        raise "name is undefined, add name= attribute" if name.nil?
        dir = File.dirname @document.htmlpath
        path = File.join(dir, name)
        push "<A HREF=\"#{name}\">Download #{name}</A>\n"
        begin
          File.open(path, "w") do |file|
            file.print file_content.join("\n")
          end
        rescue
          system "pwd; find testhtml"
        end
        file_content = []
      else
        file_content.push line
        push "  #{line}\n"
      end
    end

    return self.result.strip
  end

end

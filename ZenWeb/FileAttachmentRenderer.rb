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

    start_re = /<file\s+name\s*=\s*\"([\w\.-]+)\"\s*>/i
    end_re   = /<\/file>/i

    file_content = []
    name = nil
    self.scan_region(content, start_re, end_re) do |line|
      case line
      when start_re then
        name = $1
      when end_re then
        raise "fucked up" if name.nil?
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

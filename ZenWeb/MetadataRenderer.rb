require 'ZenWeb/GenericRenderer'

=begin

= Class MetadataRenderer

Converts all metadata references into their values.

=== Methods

=end

class MetadataRenderer < GenericRenderer

=begin

--- MetadataRenderer#render(content)

    Converts all metadata references into their values.

=end

  def render(content)

    content = content.gsub(/\#\{([^\}]+)\}/) {
      key = $1
      
      # check to see if this is a metadata entry
      val = @document[key] || nil
      
      # otherwise try to eval it. If that fails, just give text.
      unless (val) then
	begin
	  val = eval(key)
	rescue NameError
	  val = key
	rescue Exception => err
	  $stderr.puts "eval failed in MetadataRenderer for #{@document.datapath}: #{err}. Code = '#{key}'"
	  val = key
	end
      end
      
      val
    }

    return content
  end

  def include(path, remove_metadata=false)
    path = File.expand_path(File.join(File.dirname(@document.datapath), path))
    content = File.new(path).readlines

    if remove_metadata then
      content = content.reject { |line| line =~ /^\s*\#/ }
    end

    return self.render(content.join(''))
  end

end


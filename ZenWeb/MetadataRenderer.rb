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

    content=content.collect { | p |
      p.gsub!(/\#\{([^\}]+)\}/) {
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
	    $stderr.puts "eval failed in MetadataRenderer for #{@document.datapath}: #{p}."
	    val = key
	  end
	end
	
	val
      }
      p
    }

    return content
  end

end


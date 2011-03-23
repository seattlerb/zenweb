require 'ZenWeb/GenericRenderer'

=begin

= Class MetadataRenderer

Converts all metadata references into their values.

=== Methods

=end

class MetadataRenderer < GenericRenderer

  @@cache = {}

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
          # this allows evals that fail (expensive) to be cached, 
          # and good code to be eval'd every time.
          # I think this is a good balance.
          if @@cache[key] then
            val = @@cache[key]
          else
            val = eval(key)
          end
        rescue NameError => err
          val = key
          @@cache[key] = key
        rescue Exception => err
          $stderr.puts "eval failed in MetadataRenderer for #{@document.datapath}: #{err}. Code = '#{key}'"
          val = key
          @@cache[key] = key
        end
      end
      
      val
    }

    return content
  end

  @@paths = {}

  def include(path, remove_metadata=false, escape=false)
    unless @@paths.include? path then
      full_path = File.expand_path(File.join(File.dirname(@document.datapath), path))
      @@paths[path] = full_path
    else
      full_path = @@paths[path]
    end

    content = File.new(full_path).readlines

    if remove_metadata then
      content = content.reject { |line| line =~ /^\s*\#/ }
    end

    content = self.render(content.join(''))
    content.gsub!(/([<>&])/) { |x| '\\' + x } if escape

    content
  end

end


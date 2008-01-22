require 'ZenWeb/GenericRenderer'

=begin

= Class RubyCodeRenderer

Finds paragraphs prefixed with "!" and evaluates them with xmp

=== Methods

=end

class RubyCodeRenderer < GenericRenderer

=begin

--- RubyCodeRenderer#render(content)

    Finds paragraphs prefixed with "!" and evaluates them with xmp

=end

  def render(content)

    text = content.split($PARAGRAPH_RE)
    
    text.each do | p |

      if p =~ /^\s*\!/m then
        p.gsub!(/^\s*\!\s*/, '')
        
        begin
          cmd = "irb --prompt xmp --noreadline 2>/dev/null"
          puts "Running irb for code:\n#{p}" unless $TESTING
          IO.popen(cmd, "r+") do |xmp|
            xmp.puts(p + "\nexit")
            result = xmp.read
            result.gsub!(/\s+>> exit\s*\Z/, '')
            result.gsub!(/=>(.*)\Z/m, '=><EM>\1</EM>')
            push result
          end
        rescue Exception => something
          $stderr.puts "xmp: #{something}\nTrace =\n" + $@.join("\n") + "\n"
        end
      else
        push p
      end
      push ''
    end
    
    # put it back into line-by-line format
    @result = @result.join("\n").scan(/^.*[\n\r]+/)

    return self.result
  end
end

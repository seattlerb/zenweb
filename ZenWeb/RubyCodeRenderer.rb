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

    code = ""
    scan_region(content, /<ruby>/, /<\/ruby>/) do |line, context|
      case context
      when :START then
      when :END then
	code.chomp!
	$stderr.puts "eval = #{code.inspect}" if $DEBUG
	begin
	  cmd = "irb --prompt xmp --noreadline 2>/dev/null"
	  puts "Running irb for code:\n#{code}" unless $TESTING
	  IO.popen(cmd, "r+") do |xmp|
	    xmp.puts(code + "\nexit")
	    result = xmp.read
	    $stderr.puts "result = #{result.inspect}" if $DEBUG
	    result = result.split($/)[0..-2] # strip off exit

	    last = ""
	    result = result.delete_if do |l|
	      if l =~ /==>/; then
		last=l
		true
	      else
		false
	      end 
	    end

	    result.push last.sub(/^\s*==>(.*)$/, "  ==\\><EM>\\1</EM>")

	    result = result.join($/)
	    result.gsub!(/^/, '  ')

	    push result
	    push "\n" if line =~ /\n\Z/
	  end
	rescue Exception => something
	  $stderr.puts "xmp: #{something}\nTrace =\n" + $@.join("\n") + "\n"
	end
      else
	code += line.strip + "\n"
      end
    end

    return self.result
  end

  def render2(content)

    text = content.split($PARAGRAPH_RE)
    
    text.each do | p |

      if (p =~ /^\s*\!/m) then

	p.gsub!(/^[\ \t]*\![\ \t]*/, '')
	
	begin
	  cmd = "irb --prompt xmp --noreadline 2>/dev/null"
	  puts "Running irb for code:\n#{p}" unless $TESTING
	  IO.popen(cmd, "r+") do |xmp|
	    xmp.puts(p + "\nexit")
	    result = xmp.read
	    result = result.split($/)[0..-2] # strip off exit

	    last = ""
	    result = result.delete_if do |l|
	      if l =~ /==>/; then
		last=l
		true
	      else
		false
	      end 
	    end

	    result.push last.sub(/^\s*==>(.*)$/, '  ==\\><EM>\1</EM>')
	    result = result.join($/)
	    result.gsub!(/^/, '  ')

	    push result
	  end
	rescue Exception => something
	  $stderr.puts "xmp: #{something}\nTrace =\n" + $@.join("\n") + "\n"
	end
      else
	push(p)
	push("\n\n")
      end
    end
    
    return self.result
  end
end


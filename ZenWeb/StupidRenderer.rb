# this is a simple template. Globally replace Stupid with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'

=begin

= Class StupidRenderer

Maniplates the text as a whole, in really stupid ways.  Currently, as
a fun demo of metadata, we have it using the variable 'stupidmethod'
to determine what it does. There are two actions possible:

+ strip - strips vowels from the text. Good compression! :)
+ leet  - does a horrid job of making the text 7337. Scary.

=== Methods

=end

$Transcode = {
  'a' => '4', 'b' => '|3', 'c' => '<', 'd' => '|)', 'e' => '3',
  'f' => 'F', 'g' => 'G', 'h' => ']-[', 'i' => '|', 'j' => 'J',
  'k' => ']<', 'l' => 'L', 'm' => '/\/\\', 'n' => '/\/', 'o' => '0',
  'p' => 'P', 'q' => 'Q', 'r' => '/~', 's' => '$', 't' => '+',
  'u' => '|_|', 'v' => '\/', 'w' => '\/\/', 'x' => '><', 'y' => '`/',
  'z' => 'Z',
}

class StupidRenderer < GenericRenderer

=begin

--- StupidRenderer#render(content)

    Strips vowells

=end

  def render(content)

    methodname = @document['stupidmethod'] || nil
    if methodname then
      method = self.method(methodname)

      content.each { |line|
	line = method.call(line)
	push(line)
      }
    else
      @result = content.to_a
    end


    return self.result
  end

  def strip(s)
    s = s.gsub(/[aeiou]/i, '')
    return s
  end

  def leet(s)

    # this is a lot more complicated than it needs to be. Basically,
    # we didn't want variable interpolation chunks (eg #{blah}) to
    # become 7337, so we split on #{}s, work on the other parts, and
    # then fit it all back together. This should probably be moved up
    # to render.

    result = []
    new_s = s.clone
    re = /(\#\{[^\}]+\})/
    new_s.split(re).each { |chunk|
      if (chunk =~ re) then
	result.push(chunk)
      else
	chunk.gsub!(/./) { |char|
	  $Transcode[char.downcase] || char
	}
	result.push(chunk)
      end
    }

    return result.join('')
  end

end

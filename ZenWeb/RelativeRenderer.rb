require 'ZenWeb/GenericRenderer'

$Uri_Implemented = true
if RUBY_VERSION =~ /1.6.(\d+)/ then
  $Uri_Implemented = $1.to_i >= 7
end

if $Uri_Implemented then
  require 'uri'
else
  if $TESTING then
    $stderr.puts "WARNING: RelativeRenderer can not be implemented in ruby versions < 1.6.7."
    $stderr.puts "Some unit tests will fail as a result"
  end
end

=begin

= Class RelativeRenderer

Converts urls to relative urls if possible...

=== Methods

=end

class RelativeRenderer < GenericRenderer

=begin

--- RelativeRenderer.new(document)

    Instantiates RelativeRenderer.

=end

  def initialize(document)
    super(document)

    if $Uri_Implemented then
      # fake, since we don't know the domain (or care), but necessary for URI#-
      # it bombs otherwise... fun.
      @base = URI.parse("http://www.domain.com/")
      
      # @base + url will == url if url is not relative...
      @docurl = @base + URI.parse(@document.url)
    end
  end

=begin

--- RelativeRenderer#render(content)

    Converts urls that look like they can be made relative to be so...

=end

  def render(content)
    if $Uri_Implemented then
      content.each { | line |

	line.gsub!(%r%(href=\")([^\"]+)(\")%i) { |url| 
	  front  = $1
	  oldurl = $2
	  back   = $3
	  newurl = convert(oldurl)

	  front + newurl + back
	}

	push(line)
      }

      return self.result
    else
      return content
    end
end

  def convert(u)

    if $Uri_Implemented then
      oldurl = URI.parse(u)

      if oldurl.relative? then
	oldurl = @base + oldurl
	scheme = oldurl.scheme
	newurl = oldurl - @docurl
      else
	newurl = u
      end
      return newurl.to_s
    else
      return u
    end
  end
end


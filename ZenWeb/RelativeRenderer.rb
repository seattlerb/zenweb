require 'ZenWeb/GenericRenderer'

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

    # fake, since we don't know the domain (or care), but necessary for URI#-
    # it bombs otherwise... fun.
    @base = URI.parse("http://www.domain.com/")

    # @base + url will == url if url is not relative...
    @docurl = @base + URI.parse(@document.url)
  end

=begin

--- RelativeRenderer#render(content)

    Converts urls that look like they can be made relative to be so...

=end

  def render(content)
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

    return @result
  end

  def convert(u)

    oldurl = URI.parse(u)

    if oldurl.relative? then
      oldurl = @base + oldurl
      scheme = oldurl.scheme
      newurl = oldurl - @docurl
    else
      newurl = u
    end
    return newurl.to_s
  end

end


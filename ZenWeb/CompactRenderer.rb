# 
# 

require 'ZenWeb/GenericRenderer'

=begin

= Class CompactRenderer

CompactRenderer compacts HTML whitespace and comments to minimize how much text gets served.

=== Methods

=end

class CompactRenderer < GenericRenderer

=begin

     --- CompactRenderer#render(content)

     Compacts HTML blah blah DOC

=end

  def render(content)

    # protect pre blocks
    content = content.gsub(/(<pre>)([\s\S]*?)(<\/pre>)/i) do
      p1 = $1
      body = $2
      p2 = $3
      body = body.gsub(/\n/, 1.chr).gsub(/ /, 2.chr)
      p1 + body + p2
    end

    content = content.gsub(/\n\r/, '').gsub(/\s+/, ' ').gsub(/> </, '><').strip
    content = content.gsub(1.chr, "\n").gsub(2.chr, " ")

    push(content)

    return self.result
  end

end

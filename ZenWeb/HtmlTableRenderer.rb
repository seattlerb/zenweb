# this is a simple template. Globally replace HtmlTable with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'

=begin

= Class HtmlTableRenderer

Converts tab delimited data (tagged with <tabs>) into HTML tables

=== Methods

=end

class HtmlTableRenderer < GenericRenderer

=begin

     --- HtmlTableRenderer#render(content)

     Converts tab delimited data (tagged with <tabs>) into HTML tables

=end

  def render(content)

    self.each_paragraph_matching(content, /^<tabs>/i) do |p|
	first=true
	p.each_line do |line|
	  line.chomp!
	  case line
	  when /^<tabs>/ then
	    line = "<table border=\"0\">\n"
	  when /^<\/tabs>/ then
	    line = "</table>"
	  else
	    type = "td"

	    if first then
	      first = false
	      type = "th"
	    end

	    line = ("<tr><#{type}>" +
		    line.split(/\t+/).join("</#{type}><#{type}>") +
		    "</#{type}></tr>\n")
	  end
        push line
      end
    end
  
    return self.result
  end

end

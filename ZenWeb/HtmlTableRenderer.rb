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

    first=true
    self.scan_region(content, /^<tabs>/i, /^<\/tabs>/i) do |line, context|
      line.chomp!
      case context
      when :START then
	line = "<table border=\"0\">\n"

	# Add a newline if the previous paragraph butted up against us
	if ! @result.last.nil? and @result.last !~ /^\s*$/ then
	  line = "\n" + line
	end
      when :END then
	line = "</table>\n\n"
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
  
    return self.result
  end

end

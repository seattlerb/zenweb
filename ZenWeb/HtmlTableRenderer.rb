require 'ZenWeb/GenericRenderer'

class Hash
  def %(style)
    style.gsub(/%([-\d]*)\(([^\)]+)\)/) do |match|
      result = ''
      key = $2.intern
      if self.has_key?(key) then
	result = $1 ? sprintf("%*s", $1.to_i, self[key]) : self[key]
      else
	$stderr.puts "  WARNING: missing data for '#{key}' in #{self.inspect}" unless $TESTING
      end
      result
    end
  end
end

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
    pre_style = post_style = head_style = body_style = column_titles = nil

    self.scan_region(content, /^<tabs/i, /^<\/tabs>/i) do |line, context|
      line.chomp!
      case context
      when :START then
	first = true
	if line =~ /style\s*=\s*\"?([\w\.-]+)\"?/i then
	  pre_style  = @document["style_#{$1}_pre"]  || ''
	  post_style = @document["style_#{$1}_post"] || ''
	  head_style = @document["style_#{$1}_head"] || ''
	  body_style = @document["style_#{$1}"] or
	    raise "You must specify a metadata entry for 'style_#{$1}'"
	else
	  pre_style = "<table border=\"0\">\n"
	  post_style = "</table>\n" 
	  head_style = nil
	  body_style = nil
	  column_titles = nil
	end
	line = pre_style
      when :END then
	line = post_style
      else
	columns = line.split(/\t+/)
	
	if body_style then
	  if first then
	    line = head_style
	    # map the first row of data to column title positions
	    column_titles = columns.map {|x| x.intern}
	  else
	    data = {}
	    # use the column title positions to extract the data from the table
	    column_titles.each_with_index do |title, index|
	      data[title] = columns[index]
	    end
	    
	    # use our extension to hash (see above) to format the data
	    line = data % body_style
	  end
	else
	  type = first ? "th" : "td"
	  line = "<tr><#{type}>#{columns.join "</#{type}><#{type}>"}</#{type}></tr>\n"
	end
	first = false if first
      end
      push line
    end
  
    return self.result
  end

end

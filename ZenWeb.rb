#!/usr/local/bin/ruby -w

require 'cgi'

    # TODO: sitemap must push self on when url = self.url

=begin
A ZenWebsite is a collection of pages, one of which is a sitemap
that knows the order and hierarchy of those pages.
=end

class ZenWebsite

  include CGI::Html4Tr

  VERSION = '2.0.0'

  # TODO: figure out why I shouldn't provide access to the last two
  attr_reader :datadir, :htmldir, :sitemap, :documents, :doc_order

  def initialize(sitemapUrl, datadir, htmldir)

    puts "Preprocessing website..." if $DEBUG

    unless (test(?d, datadir)) then
      raise ArgumentError, "datadir must be a valid directory"
    end

    @datadir = datadir
    @htmldir = htmldir
    @sitemap = ZenSitemap.new(sitemapUrl, self)
    @documents = @sitemap.documents
    @doc_order = @sitemap.doc_order

    # Tell each document to notify it's parent about itself.
    @documents.each_value { | doc |
      parentURL = doc.parentURL
      parentDoc = self[parentURL]
      if (parentDoc and parentURL != doc.url) then
	parentDoc.addSubpage(doc.url)
      end
    }

    puts "Generating website..." if $DEBUG

  end

  def renderSite()

    #1) Open Sitemap:
    #  1) Read all urls:
    #    1) Find page corresponding to url.
    #    2) Open file.
    #    3) Generically parse file, extracting metadata and content.
    #    4) Based on current metadata, instantiate the correct type of page.
    #2) Generate a makefile OR dependency map.
    #3) Run make OR iterate over each page instance and IF it should
    #   be generated, generate it.
    
    unless (test(?d, self.htmldir)) then
      Dir.mkdir(self.htmldir)
    end

    self.doc_order.each { | url |
      puts url if $DEBUG
      doc = @documents[url]
      doc.render()
    }

  end

  ############################################################
  # Accessors:

  def [](url)
    return @documents[url] || nil
  end

end

=begin
A ZenDocument is an object representing a unit of input data,
typically a file. It may correspond to multiple output data (one
document could create several HTML pages).
=end

class ZenDocument

  # These are done manually
  # attr_reader :datapath, :htmlpath

  attr_reader :url, :metadata, :content

  # TODO: why should I allow this?
  attr_reader :subpages, :website

=begin
There are 3 different types of relationships in a document. Parent,
Child, Sibling. DOC
=end

  def initialize(url, website)

    @url      = url
    @website  = website
    @datapath = nil
    @htmlpath = nil
    @subpages = []
    @content  = []

    unless (test(?f, self.datapath)) then
      raise ArgumentError, "url #{url} doesn't exist in #{self.datadir}"
    end

    @metadata = Metadata.new(self.dir, self.datadir)

    self.parseMetadata

  end

  def parseMetadata
    # 1) Open file
    # 2) Parse w/ generic parser for metadata, stripping it out.
    count = 0
    IO.foreach(self.datapath) { | line |
      count += 1
      # REFACTOR: class Metadata also has this.
      if (line =~ /^\#\s*(\"(?:\\.|[^\"]+)\"|[^=]+)\s*=\s*(.*?)\s*$/) then
	begin
	  key = $1
	  val = $2

	  key = eval(key)
	  val = eval(val)
	rescue Exception
	  $stderr.puts "#{self.datapath}:#{count}: eval failed: #{line}"
	else
	  self[key] = val
	end
      else
	self.content.push(line)
      end
    }
  end

  def renderContent()

    # contents already preparsed for metadata
    result = self.content

    # 3) Use metadata to determine the rest of the renderers.
    renderers = self['renderers'] || [ 'GenericRenderer' ]

    # 4) For each renderer in list:

    renderers.each { | renderer |

      renderer = renderer.intern

      # 4.1) Invoke a renderer by that name
      # TODO: wrap in a try/catch
      theClass = Module.const_get(renderer)
      renderer = theClass.send("new", self)

      # 4.2) Pass entire file contents to renderer and replace w/ result.
      result = renderer.render(result)
    }

    return result.join('')
  end

  def render()

    path = self.htmlpath
    dir = File.dirname(path)

    unless (test(?d, dir)) then
      Dir.mkdir(dir)
    end

    content = self.renderContent
    out = File.new(self.htmlpath, "w")
    out.print(content)
    out.close

  end

  def parentURL()
    url = self.url.clone

    url.sub!(/\/[^\/]+\/index.html$/, "/index.html")
    url.sub!(/\/[^\/]+$/, "/index.html")

    return url
  end

  # protected

  def addSubpage(url)
    if (url != self.url) then
      self.subpages.push(url)
    end
  end

=begin
Convert a string composed of lines prefixed by plus signs into an
array of those strings, sans plus signs. If a line is indented with
tabs, then the lines at that indention level will become an array of
their own, to be added to the encompassing array.
=end

  def createList(data)

    if (data.is_a?(String)) then
      data = data.split($/)
    end

    min = -1
    i = 0
    len = data.size

    while (i < len)
      if (min == -1) then

	# looking for initial match:
	if (data[i] =~ /^\t(\t*.*)/) then

	  # replace w/ one less tab, and record that we have a match 
	  data[i] = $1
	  min = i
	end
      else

	# found match, looking for mismatch
	if (data[i] !~ /^\t(\t*.*)/ or i == len) then

	  # found mismatch, replacing w/ sublist
	  data[min..i-1] = [ createList(data[min..i-1]) ]
	  # resetting appropriate values
	  len = data.size
	  i = min
	  min = -1
	else
	  data[i] = $1
	end
      end
      i += 1
    end

    if (i >= len - 1 and min != -1) then
      data[min..i-1] = [ createList(data[min..i-1]) ]
    end

    return data
  end

  ############################################################
  # Accessors:

  def parent
    parentURL = self.parentURL
    parent = (parentURL != self.url ? self.website[parentURL] : nil)
    return parent
  end

  def dir()
    return File.dirname(self.datapath)
  end

  def datapath()

    if (@datapath.nil?) then
      datapath = "#{self.datadir}#{@url}"
      datapath.sub!(/\.html$/, "")
      datapath.sub!(/~/, "")
      @datapath = datapath
    end

    return @datapath
  end

  def htmlpath()

    if (@htmlpath.nil?) then
      htmlpath = "#{self.htmldir}#{@url}"
      htmlpath.sub!(/~/, "")
      @htmlpath = htmlpath
    end

    return @htmlpath
  end

  def fulltitle
    title = self['title'] || "Unknown"
    subtitle = self['subtitle'] || nil

    return title + (subtitle ? ": " + subtitle : '')
  end

  def [](key)
    return @metadata[key] || nil
  end

  def []=(key, val)
    @metadata[key] = val
  end

  def datadir
    return self.website.datadir
  end

  def htmldir
    return self.website.htmldir
  end

end

=begin

A ZenSitemap is a ZenDocument that knows about the order and hierarchy
of all of the other pages in the website.

TODO: how much difference is there between a website and a sitemap?

=end

class ZenSitemap < ZenDocument

  attr_reader :documents, :doc_order

  def initialize(url, website)
    super(url, website)

    @documents = {}
    @doc_order = []

    self['title']       ||= "SiteMap"
    self['description'] ||= "This page links to every page in the website."
    self['keywords']    ||= "sitemap, website"

    count = 0
    IO.foreach(self.datapath) { |f|
      count += 1
      f.chomp!

      f.gsub!(/\s*\#.*/, '')
      f.strip!

      next if f == ""

      if (f =~ /^\s*(\w+)\s*=\s*(.*)/) then
	# RETIRE: no more metadata in sitemap
	self[$1] = $2
      elsif f =~ /^\s*([\/-_~\.\w]+)$/
	url = $1

	if (url == self.url) then
	  doc = self
	else
	  doc = ZenDocument.new(url, @website)
	end

	self.documents[url] = doc
	self.doc_order.push(url)
      else
	$stderr.puts "WARNING on line #{count}: syntax error: '#{f}'"
      end
    }

  end # initialize

end

=begin
Metadata provides a hash whose content comes from a file whose name is
fixed. Metadata will also be provided by metadata files in parent
directories, up to a specified directory, or "/" by default.
=end

class Metadata < Hash
  
  # TODO: set up a metadata dictionary structure w/ parent refs
  def initialize(directory, toplevel = "/")

    if (test(?f, directory)) then
      directory = File.dirname(directory)
    end

    self.loadFromDirectory(directory, toplevel)

  end

  def save(file)
    out = File.open(file, "w")
    self.each_key { | key |
      out.printf("%s = %s\n", key.inspect, self[key].inspect)
    }
    out.close
  end

  def loadFromDirectory(directory, toplevel, count = 1)

    raise "too many recursions" if (count > 20)

    if (directory != toplevel && directory != "/" && directory != ".") then
      self.loadFromDirectory(File.dirname(directory), toplevel, count + 1)
    end

    file = directory + "/" + "metadata.txt"
    if (test(?f, file)) then
      self.load(file)
    end

  end

  def load(file)

    count = 0
    IO.foreach(file) { | line |
      count += 1
      if (line =~ /^\s*(\"(?:\\.|[^\"]+)\"|[^=]+)\s*=\s*(.*?)\s*$/) then

	# REFACTOR: this is duplicated from above
	begin
	  key = $1
	  val = $2

	  key = eval($1)

	  if key == "today" then
	    puts "trying to eval '#{val}'"
	  end
	  
	  val = eval($2)
	rescue Exception
	  $stderr.puts "WARNING on line #{count}: eval failed: #{line}: #{$!}"
	else
	  self[key] = val
        end
      elsif (line =~ /^\s*$/) then
	# ignore
      elsif (line =~ /^\#.*$/) then
	# ignore
      else
	$stderr.puts "WARNING on line #{count}: cannot parse: #{line}"
      end
    }
  end

end

class GenericRenderer

  def initialize(document)
    @document = document
    @website = @document.website
    @sitemap = @website.sitemap
    @result = []
  end

  def push(obj)

    if obj.is_a?(String) then
      @result.push(obj)
    elsif obj.is_a?(Array) then
      @result.concat(obj)
    else
      @result.push(obj.to_s)
    end  
  end

  def unshift(obj)
    @result.unshift(obj)
  end

  def render(content)
    return content
  end

end

class SitemapRenderer < GenericRenderer

  def render(content)

    urls = @sitemap.doc_order.clone

    @document['subtitle'] ||= "There are #{urls.size} pages in this website."
    urls.each { | url |
      indent = url.sub(/\.html$/, "")
      indent.sub!(/\/index$/, "")
      indent.sub!(/^\//, "")
      indent.gsub!(/[^\/]+\//, "\t")
      
      if indent =~ /^(\t*).*/ then
	indent = $1
      end
      
      doc      = @website[url]
      title    = doc.fulltitle
      
      push("#{indent}+ <A HREF=\"#{url}\">#{title}</A>\n")
    }

    return @result
  end
end

class HtmlRenderer < GenericRenderer

  def render(content)
    raise "Subclass Responsibility"
  end

  def array2html(list, indent=0)
    result = ""

    result += ("<!-- " + list.inspect + "-->\n") if $DEBUG

    indent1 = "  " * indent
    indent2 = "  " * (indent + 1)

    result += (indent1 + "<UL>\n")
    list.each { | l |
      if (l.is_a?(Array)) then
	result += self.array2html(l, indent+1)
      else
	result += (indent2 + "<LI>" + l.to_s + "</LI>\n")
      end
    }
    result += (indent1 + "</UL>\n")
    
    return result
  end

end

class HtmlTemplateRenderer < HtmlRenderer

  def render(content)
    author      = @document['author']
    banner      = @document['banner']
    bgcolor     = @document['bgcolor']
    copyright   = @document['copyright']
    description = @document['description']
    email       = @document['email']
    keywords    = @document['keywords']
    rating      = @document['rating'] || 'general'
    stylesheet  = @document['stylesheet']
    subtitle    = @document['subtitle']
    title       = @document['title'] || 'Unknown Title'

    titletext   = @document.fulltitle

    # header
    push("<HTML>\n")
    push("<HEAD>\n")
    push("<TITLE>#{titletext}</TITLE>\n")

    # TODO: check both of these against the standard
    push("<LINK REV=\"MADE\" HREF=\"mailto:#{email}\">\n") if email
    push("<LINK REL=\"STYLESHEET\" HREF=\"#{stylesheet}\" type=text/css title=\"#{stylesheet}\">\n") if stylesheet

    push("<META NAME=\"rating\" CONTENT=\"#{rating}\">\n")
    push("<META NAME=\"GENERATOR\" CONTENT=\"ZenWeb #{ZenWebsite::VERSION}\">\n")
    push("<META NAME=\"author\" CONTENT=\"#{author}\">\n") if author
    push("<META NAME=\"copyright\" CONTENT=\"#{copyright}\">\n") if copyright
    push("<META NAME=\"keywords\" CONTENT=\"#{keywords}\">\n") if keywords
    push("<META NAME=\"description\" CONTENT=\"#{description}\">\n") if description

    push("</HEAD>\n")
    push("<BODY" + (bgcolor ? " BGCOLOR=\"#{bgcolor}\"" : '') + ">\n")

    push("<IMG SRC=\"#{banner\}\" BORDER=0><BR>\n") if banner

    self.navbar

    push("<H1>#{title}</H1>\n")
    push("<H2>#{subtitle}</H2>\n") if subtitle
    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    push(content)

    # TODO: break into own renderer
    subpages = @document.subpages.clone
    if (subpages.length > 0) then
      push("<H2>Subpages:</H2>\n\n")
      subpages.each_index { | index | 
	url      = subpages[index]
	doc      = @website[url]
	title    = doc.fulltitle

	subpages[index] = ("<A HREF=\"#{url}\">" +
			   title +
			   "</A>")
      }
      push(self.array2html(subpages) + "\n")
    end

    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    self.navbar

    push("\n\n</BODY>\n</HTML>\n")

    return @result
  end

  def navbar

    sep = " / "
    sitemap = @website.sitemap
    search  = @website["/Search.html"]

    push("<P>\n")

    push("<A HREF=\"#{sitemap.url}\"><STRONG>Sitemap</STRONG></A>")

    if search then
      push(" | ")
      push("<A HREF=\"#{search.url}\"><STRONG>Search</STRONG></A>")
    end

    push(" || ")

    path = []
    current = @document

    while current
      current = current.parent
      path.unshift(current) if current
    end

    path.each { | doc |
      url = doc.url
      title = doc['title']

      push("<A HREF=\"#{url}\">#{title}</A>\n")
      push(sep)
    }

    push(@document['title'])

    push("</P>\n")

    return []
  end

end

class TextToHtmlRenderer < HtmlRenderer

  def render(content)

    text = content.join('')
    content = text.split(/#{$\/}#{$\/}+/)

    content.each { | p |

      # massage a little
      p.sub!(/^#{$\/}+/, '')
      p.chomp!

      # TODO: break into own renderer
      # glossary substitutions:
      p.gsub!(/\#\{([^\}]+)\}/) {
	key = $1
	val = @document[key] || nil

	# TODO: should we allow embedded ruby?
	
	val = key unless val
	val
      }

      # TODO: break into own renderer
      # url substitutions
      # FIX: needs to NOT substitute whole urls!
      p.gsub!(/([^=\"])((http|ftp|mailto):(\S+))/) {
	pre = $1
	url = $2
	text = $4

	text.gsub!(/\//, " ")
	text.strip!
	text.gsub!(/ /, " /")

	"#{pre}<A HREF=\"#{url}\">#{text}</A>"
      }

      # TODO: needs to be more selective?
      p.gsub!(/\\&/, "&amp;")
      p.gsub!(/\\</, "&lt;")
      p.gsub!(/\\>/, "&gt;")

      if (p =~ /^(\*\*+)\s*(.*)$/) then
	level = $1.length
	push("<H#{level}>#{$2}</H#{level}>\n\n")
      elsif (p =~ /^---+$/) then
	push("<HR SIZE=\"1\" NOSHADE>\n\n")
      elsif (p =~ /^===+$/) then
	push("<HR SIZE=\"2\" NOSHADE>\n\n")
      elsif (p =~ /^\t*\+/) then

	p.gsub!(/^(\t*)\+\s*(.*)$/) { $1 + $2 }

	list = @document.createList(p)

	if (list) then
	  push(self.array2html(list) + "\n")
	end
      elsif (p =~ /^\ \ / and p !~ /^[^\ ]/) then
	p.gsub!(/^\ \ /, '')
	push("<PRE>" + p + "</PRE>\n\n")
      else
	push("<P>" + p + "</P>\n\n")
      end
    }

    return @result

  end

end

class HeaderRenderer < GenericRenderer

  def render(content)

    header = @document['header'] || nil

    if header then
      placed = false

      content.each { | line |

	push(line)

	if (line =~ /<BODY/i) then
	  push(header)
	  placed = true
	end
      }

      @result.unshift(header) unless placed
    end

    return content
  end
end

class FooterRenderer < GenericRenderer

  def render(content)

    footer = @document['footer'] || nil

    if footer then

      placed = false

      content.each { | line |

	if (line =~ /<\/BODY>/i) then
	  push(footer)
	  placed = true
	end

	push(line)
      }

      push(footer) unless placed
    end

    return @result
  end
end

############################################################
# Main:

if __FILE__ == $0
  path = ARGV.shift || raise(ArgumentError, "Need a sitemap path to load.")
  ZenWebsite.new("/SiteMap.html", path, path + "html").renderSite()
end

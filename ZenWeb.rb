#!/usr/local/bin/ruby -w

require 'cgi'

=begin
= ZenWeb

A set of classes for organizing and formating a collection of related
documents.

= SYNOPSIS

  ZenWeb.rb directory

= DESCRIPTION

A ZenWebsite is a collection of documents in one or more directories,
organized by a sitemap. The sitemap references every document in the
collection and maintains their order and hierarchy.

Each directory may contain a metadata file of key/value pairs that can
be used by ZenWeb and by the documents themselves. Each metadata file
can override values from the metadata file in the parent
directory. Each document can also define metadata, which will also
override any values from the metadata files.

ZenWeb processes the sitemap and in turn all related documents. ZenWeb
uses a series of renderers (determined by metadata) to process the
documents and writes the end result to disk.

There are 5 major classes:

* ((<Class ZenWebsite>))
* ((<Class ZenDocument>))
* ((<Class ZenSitemap>))
* ((<Class Metadata>))
* ((<Class GenericRenderer>))

And 6 renderer classes:

* ((<Class SitemapRenderer>))
* ((<Class HtmlRenderer>))
* ((<Class HtmlTemplateRenderer>))
* ((<Class TextToHtmlRenderer>))
* ((<Class HeaderRenderer>))
* ((<Class FooterRenderer>))

=end

=begin

= Class ZenWebsite

ZenWebsite is the top level class. It is responsible for driving the
process.

=== Methods

=end

class ZenWebsite

  include CGI::Html4Tr

  VERSION = '2.0.0'

  # TODO: figure out why I shouldn't provide access to the last two
  attr_reader :datadir, :htmldir, :sitemap, :documents, :doc_order

=begin

--- ZenWeb.new(sitemapURL, datadir, htmldir)

    Creates a new ZenWeb instance and preprocesses the sitemap and all
    referenced documents.

=end

  def initialize(sitemapUrl, datadir, htmldir)

    puts "Preprocessing website..." unless $TESTING

    unless (test(?d, datadir)) then
      raise ArgumentError, "datadir must be a valid directory"
    end

    @datadir = datadir
    @htmldir = htmldir
    @sitemap = ZenSitemap.new(sitemapUrl, self)
    @documents = @sitemap.documents
    @doc_order = @sitemap.doc_order

    # Tell each document to notify it's parent about itself.
    @doc_order.each { | url |
      doc = self[url]
      parentURL = doc.parentURL
      parentDoc = self[parentURL]
      if (parentDoc and parentURL != url) then
	parentDoc.addSubpage(doc.url)
      end
    }

    puts "Generating website..." unless $TESTING

  end

=begin

--- ZenWeb#renderSite

    Iterates over all of the documents and asks them to ((<render|ZenDocument#render>)).

=end

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
      puts url unless $TESTING
      doc = @documents[url]
      doc.render()
    }

  end

  ############################################################
  # Accessors:

=begin

--- ZenWebsite#[](url)

    Accesses a document by url.

=end

  def [](url)
    return @documents[url] || nil
  end

end

=begin

= Class ZenDocument
A ZenDocument is an object representing a unit of input data,
typically a file. It may correspond to multiple output data (one
document could create several HTML pages).
=== Methods

=end

class ZenDocument

  # These are done manually
  # attr_reader :datapath, :htmlpath

  attr_reader :url, :metadata, :content

  # TODO: why should I allow this?
  attr_reader :subpages, :website

=begin

--- ZenDocument.new(url, website)

    Creates a new ZenDocument instance and preprocesses the metadata.

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

=begin

--- ZenDocument#parseMetadata

    Opens the datafile and preparses the content for metadata. In a
    document, metadata has the basic form of "# key = val" where key
    and val are both proper ruby representations of the values in
    question. Eval is used to convert them from textual representation
    to an actual ruby object.

=end

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

=begin

--- ZenDocument#renderContent

    Renders the content of the document by passing the content to a
    series of renderers. The renderers are specified by metadata as an
    array of strings and each one must implement the GenericRenderer
    interface.

=end

  def renderContent()

    # contents already preparsed for metadata
    result = self.content

    # 3) Use metadata to determine the rest of the renderers.
    renderers = self['renderers'] || [ 'GenericRenderer' ]

    # 4) For each renderer in list:

    renderers.each { | rendererName |

      rendererName = rendererName.intern

      # 4.1) Invoke a renderer by that name
      begin
	theClass = Module.const_get(rendererName)
	renderer = theClass.send("new", self)
	# 4.2) Pass entire file contents to renderer and replace w/ result.
	result = renderer.render(result)
      rescue NameError
	raise NotImplementedError, "Renderer #{rendererName} is not implemented or loaded"
      end
    }

    return result.join('')
  end

=begin

--- ZenDocument#render

    Gets the rendered content from ((<ZenDocument#renderContent>)) and
    writes it to disk.

=end

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

=begin

--- ZenDocument#parentURL

    Returns the parent url of this document. That is either the
    index.html document of the current directory, or the parent
    directory.

=end

  def parentURL()
    url = self.url.clone

    url.sub!(/\/[^\/]+\/index.html$/, "/index.html")
    url.sub!(/\/[^\/]+$/, "/index.html")

    return url
  end

  # protected

=begin

--- ZenDocument#addSubpage

    Adds a url to the list of subpages of this document.

=end

  def addSubpage(url)
    if (url != self.url) then
      self.subpages.push(url)
    end
  end

=begin

--- ZenDocument#createList

    Convert a string composed of lines prefixed by plus signs into an
    array of those strings, sans plus signs. If a line is indented
    with tabs, then the lines at that indention level will become an
    array of their own, to be added to the encompassing array.

    TODO: find a proper place for this, it does not belong in ZenDocument.

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

=begin

--- ZenDocument#parent

    Returns the document object corresponding to the parentURL.

=end

  def parent
    parentURL = self.parentURL
    parent = (parentURL != self.url ? self.website[parentURL] : nil)
    return parent
  end

=begin

--- ZenDocument#dir

    Returns the path of the directory for this url.

=end

  def dir()
    return File.dirname(self.datapath)
  end

=begin

--- ZenDocument#datapath

    Returns the full path to the data document.

=end

  def datapath()

    if (@datapath.nil?) then
      datapath = "#{self.datadir}#{@url}"
      datapath.sub!(/\.html$/, "")
      datapath.sub!(/~/, "")
      @datapath = datapath
    end

    return @datapath
  end

=begin

--- ZenDocument#htmlpath

    Returns the full path to the rendered document.

=end

  def htmlpath()

    if (@htmlpath.nil?) then
      htmlpath = "#{self.htmldir}#{@url}"
      htmlpath.sub!(/~/, "")
      @htmlpath = htmlpath
    end

    return @htmlpath
  end

=begin

--- ZenDocument#fulltitle

    Returns the concatination of the title and subtitle, if any.

=end

  def fulltitle
    title = self['title'] || "Unknown"
    subtitle = self['subtitle'] || nil

    return title + (subtitle ? ": " + subtitle : '')
  end

=begin

--- ZenDocument#[](key)

    Returns the metadata corresponding to ((|key|)), or nil.

=end

  def [](key)
    return @metadata[key] || nil
  end

=begin

--- ZenDocument#[]=(key, val)

    Sets the metadata value at ((|key|)) to ((|val|)).

=end

  def []=(key, val)
    @metadata[key] = val
  end

=begin

--- ZenDocument#datadir

    Returns the directory that all documents are read from.

=end

  def datadir
    return self.website.datadir
  end

=begin

--- ZenDocument#htmldir

    Returns the directory that all rendered documents are written to.

=end

  def htmldir
    return self.website.htmldir
  end

end

=begin

= Class ZenSitemap

A ZenSitemap is a type of ZenDocument represents a file that consists
of lines of urls. Each of those urls will correspond to a file in the
((<datadir|ZenWebsite#datadir>)).

A ZenSitemap is a ZenDocument that knows about the order and hierarchy
of all of the other pages in the website.

TODO: how much difference is there between a website and a sitemap?

=== Methods

=end

class ZenSitemap < ZenDocument

  attr_reader :documents, :doc_order

=begin

--- ZenSitemap.new(url, website)

    Creates a new ZenSitemap instance and processes the sitemap
    content instantiating a ZenDocument for every referenced document
    in the sitemap.

=end

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

      if f =~ /^\s*([\/-_~\.\w]+)$/
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

= Class Metadata

Metadata provides a hash whose content comes from a file whose name is
fixed. Metadata will also be provided by metadata files in parent
directories, up to a specified directory, or "/" by default.

=== Methods

=end

class Metadata < Hash

=begin

--- Metadata.new(directory, toplevel = "/")

    Instantiates a new metadata object and loads the data from
    ((|directory|)) up to the ((|toplevel|)) directory.

    TODO: set up a metadata dictionary structure w/ parent refs

=end

  def initialize(directory, toplevel = "/")

    if (test(?f, directory)) then
      directory = File.dirname(directory)
    end

    self.loadFromDirectory(directory, toplevel)

  end

=begin

--- ZenSitemap#save(file)

    Saves the current structure to file ((|file|)).

=end

  def save(file)
    out = File.open(file, "w")
    self.each_key { | key |
      out.printf("%s = %s\n", key.inspect, self[key].inspect)
    }
    out.close
  end

=begin

--- ZenSitemap#loadFromDirectory(directory, toplevel, count=1)

    Loads a series of metadata files from the directory ((|toplevel|))
    down to ((|directory|)). Each load in turn may override previous
    values.

=end

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

=begin

--- ZenSitemap#load(file)

    Loads a specific file ((|file|)). If any keys already exist that
    are specifed in the file, then they are overridden.

=end

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

=begin

= Class GenericRenderer

A GenericRenderer provides an interface for all renderers. It renders
nothing itself.

=== Methods

=end

class GenericRenderer

=begin

--- GenericRenderer.new(document)

    Instantiates a generic renderer with a reference to
    ((|document|)), it\'s website and sitemap.

=end

  def initialize(document)
    @document = document
    @website = @document.website
    @sitemap = @website.sitemap
    @result = []
  end

=begin

--- GenericRenderer#push(obj)

    Pushes a string representation of ((|obj|)) onto the result
    array. If ((|obj|)) is an array, it iterates each item and pushes
    them (recursively). If it is not an array, it pushes (({obj.to_s})).

=end

  def push(obj)
    if obj.is_a?(Array) then
      obj.each { | item |
	self.push(item)
      }
    else
      @result.push(obj.to_s)
    end
  end

=begin

--- GenericRenderer#unshift(obj)

    Same as ((<GenericRenderer#push>)) but prepends instead of appends.

=end

  def unshift(obj)

    if obj.is_a?(Array) then
      obj.reverse.each { | item |
	self.unshift(item)
      }
    else
      @result.unshift(obj.to_s)
    end

  end

=begin

--- GenericRenderer#render(content)

    Renders the content. Does nothing in GenericRenderer, but is
    expected to be overridden by subclasses. ((|content|)) is an array
    of strings and render must return an array of strings.

=end

  def render(content)
    return content
  end

end

=begin

= Class SitemapRenderer

Converts a sitemap file into output suitable for
((<Class TextToHtmlRenderer>)).

=== Methods

=end

class SitemapRenderer < GenericRenderer

=begin

--- SitemapRenderer#render(content)

    Converts a sitemap file into output suitable for ((<Class TextToHtmlRenderer>)).

=end

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

=begin

= Class HtmlRenderer

Abstract superclass that provides common functionality for those
renderers that produce HTML.

=== Methods

=end

class HtmlRenderer < GenericRenderer

=begin

--- HtmlRenderer#render(content)

    Raises an exception. This is subclass responsibility as this is an
    abstract class.

=end

  def render(content)
    raise "Subclass Responsibility"
  end

=begin

--- HtmlRenderer#array2html

    Converts an array (of arrays, potentially) into an unordered list.

=end

  def array2html(list, indent=0)
    result = ""

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

=begin

= Class HtmlTemplateRenderer

Generates a consistant HTML page header and footer, including a
navigation bar, title, subtitle, and appropriate META tags.

=== Methods

=end

class HtmlTemplateRenderer < HtmlRenderer

=begin

--- HtmlTemplateRenderer#render(content)

    Renders a standardized HTML header and footer. This currently also
    includes a navigation bar and a list of subpages, which will
    probably be broken out to their own renderers soon.

=end

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

=begin

--- HtmlTemplateRenderer#navbar

    Generates a navbar that contains a link to the sitemap, search
    page (if any), and a fake "breadcrumbs" trail which is really just
    a list of all of the parent titles up the chain to the top.

=end

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

=begin

= Class TextToHtmlRenderer

Converts a fairly plain text format into styled HTML.

=== Methods

=end

class TextToHtmlRenderer < HtmlRenderer

=begin

--- TextToHtmlRenderer#render(content)

    Converts a simple plaintext format into formatted HTML. Includes
    paragraphing, embedded variables, lists, rules, preformatted
    blocks, and embedded HTML. See the demo pages for a complete
    description on how to use this.

=end

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
      p.gsub!(/([^=\"])((http|ftp|mailto):(\S+))/) {
	pre = $1
	url = $2
	text = $4

	text.gsub!(/\//, " ")
	text.strip!
	text.gsub!(/ /, " /")

	"#{pre}<A HREF=\"#{url}\">#{text}</A>"
      }

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

=begin

= Class HeaderRenderer

Inserts a header based on metadata.

=== Methods

=end

class HeaderRenderer < GenericRenderer

=begin

--- HeaderRenderer#render(content)

    Adds a header if the ((|header|)) metadata item exists. If the
    document contains a BODY HTML tag, then the header immediately
    follows it, otherwise it is simply at the top.

=end

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

=begin

= Class FooterRenderer

Inserts a footer based on metadata.

=== Methods

=end

class FooterRenderer < GenericRenderer

=begin

--- FooterRenderer#render(content)

    Adds a footer if the ((|footer|)) metadata item exists. If the
    document contains a BODY close HTML tag, then the footer
    immediately precedes it, otherwise it is simply at the bottom.

=end

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
  $TESTING = FALSE unless defined? $TESTING
  path = ARGV.shift || raise(ArgumentError, "Need a sitemap path to load.")
  ZenWebsite.new("/SiteMap.html", path, path + "html").renderSite()
end
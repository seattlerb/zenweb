#!/usr/local/bin/ruby -w

############################################################
# Pre-stupid-metadata cache:
############################################################
# 33947 Metadata.load.foreach
# 19533 ZenDocument.parseMetadata.foreach
#   452 Metadata.load
#   225 ZenSitemap.initialize.foreach
#   221 ZenDocument.parseMetadata
#     1 ZenSitemap.initialize

#   %   cumulative   self              self     total
#  time   seconds   seconds    calls  ms/call  ms/call  name
#  26.39    60.79     60.79      674    90.19   209.73  IO#foreach
#  15.56    96.63     35.84    54379     0.66     0.95  Object#methodcall
#  11.88   124.00     27.37    61035     0.45     0.87  GenericRenderer#push
#   6.46   138.88     14.88     2012     7.40   355.25  Array#each
#   4.89   150.14     11.26    59307     0.19     0.30  Kernel.eval

# real    4m20.347s
# user    3m51.917s
# sys     0m21.503s
############################################################
# Post-stupid-metadata cache:
############################################################
# 19533 ZenDocument.parseMetadata.foreach
#   452 Metadata.load
#   225 ZenSitemap.initialize.foreach
#   221 ZenDocument.parseMetadata
#   173 Metadata.load.foreach
#     1 ZenSitemap.initialize

#   %   cumulative   self              self     total
#  time   seconds   seconds    calls  ms/call  ms/call  name
#  22.51    26.91     26.91    61035     0.44     0.87  GenericRenderer#push
#  12.26    41.58     14.66     2012     7.29   190.62  Array#each
#  11.12    54.88     13.30      230    57.81   157.00  IO#foreach
#  10.47    67.40     12.52    20605     0.61     0.89  Object#methodcall

# real    2m20.308s
# user    2m1.025s
# sys     0m14.965s
############################################################

# require "profile"
require 'cgi'
require 'ftools'

$TESTING = FALSE unless defined? $TESTING

$methodcalls = {}
$methodcalls.default= 0

at_exit {
  $methodcalls.sort {|a,b| b[1]<=>a[1]}.each { | key, val |
    printf "%5d %s\n", val, key
  }
}

def methodcall(meth)

  $methodcalls[meth] += 1

  if $DEBUG then
    $stderr.puts meth

    for c in caller(1)
      print "  ", c, "\n"
    end
  end

end

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

And many renderer classes. For example:

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

  VERSION = '2.8.0'

  attr_reader :datadir, :htmldir, :sitemap
  attr_reader :documents if $TESTING
  attr_reader :doc_order if $TESTING

=begin

--- ZenWebsite.new(sitemapURL, datadir, htmldir)

    Creates a new ZenWebsite instance and preprocesses the sitemap and
    all referenced documents.

=end

  def initialize(sitemapUrl, datadir, htmldir)

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

  end

=begin

--- ZenWebsite#renderSite

    Iterates over all of the documents and asks them to
    ((<render|ZenDocument#render>)).

=end

  def renderSite()

    puts "Generating website..." unless $TESTING

    unless (test(?d, self.htmldir)) then
      File::makedirs(self.htmldir)
    end

    @doc_order.each { | url |
      doc = @documents[url]

      if doc.render() then
	puts url unless $TESTING
      end
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

=begin

--- ZenWebsite.banner()

    Returns a string containing the ZenWeb banner including the version.

=end
  
  def ZenWebsite.banner()
    return "ZenWeb v. #{ZenWebsite::VERSION}"
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

  # These are done manually:
  # attr_reader :datapath, :htmlpath, :metadata
  attr_reader :url, :subpages, :website, :content
  attr_writer :content if $TESTING

=begin

--- ZenDocument.new(url, website)

    Creates a new ZenDocument instance and preprocesses the metadata.

=end

  def initialize(url, website)

    raise ArgumentError, "url was nil" if url.nil?
    raise ArgumentError, "web was nil" if website.nil?

    @url      = url
    @website  = website
    @datapath = nil
    @htmlpath = nil
    @subpages = []
    @content  = []

    unless (test(?f, self.datapath)) then
      raise ArgumentError, "url #{url} doesn't exist in #{self.datadir}"
    end

    @metadata = nil

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

#    methodcall("ZenDocument.parseMetadata")

    IO.foreach(self.datapath) { | line |
#      methodcall("ZenDocument.parseMetadata.foreach")
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
	newresult = renderer.render(result)
	result = newresult
      rescue NameError => something
	raise NotImplementedError, "Renderer #{rendererName} is not implemented or loaded (#{something})"
      end
    }

    return result.join('')
  end

=begin

--- ZenDocument#render

    Gets the rendered content from ((<ZenDocument#renderContent>)) and
    writes it to disk. Returns true if it rendered the document.

=end

  def render()
    if self.newerThanTarget then
      path = self.htmlpath
      dir = File.dirname(path)
      
      unless (test(?d, dir)) then
	File::makedirs(dir)
      end
      
      content = self.renderContent
      out = File.new(self.htmlpath, "w")
      out.print(content)
      out.close
      return true
    else
      return false
    end
  end

=begin

--- ZenDocument#newerThanTarget

    Returns true if the sourcefile is newer than the targetfile.
    TODO: make it return true if the sitemap is newer

=end

  def newerThanTarget()
    data = self.datapath
    html = self.htmlpath

    if test(?f, html) then
      return test(?>, data, html)
    else
      return true
    end
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

=begin

     --- ZenDocument#createHash

     Convert a string composed of lines prefixed one of two delimiters
     into a hash. If the delimiter is "%-", then that string is used
     as the key to the hash. If the delimiter is "%=", then that
     string is used as the value to the hash.

=end

  def createHash(data)

    # WARN: this needs to be ordered
    result = {}

    if (data.is_a?(String)) then
      data = data.split($/)
    end

    key = nil
    data.each { |line|
      if (line =~ /^\s*%-\s*(.*)/) then
	key = $1
      elsif (line =~ /^\s*%=\s*(.*)/) then
	val = $1

	if (key) then
	  # WARN: maybe do something if already defined?
	  result[key] = val
	end

      else
	# nothing
      end
    }

    return result
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
    return self.metadata[key]
  end

=begin

--- ZenDocument#[]=(key, val)

    Sets the metadata value at ((|key|)) to ((|val|)).

=end

  def []=(key, val)
    self.metadata[key] = val
  end

def metadata
  if @metadata.nil? then
    @metadata = Metadata.new(self.dir, self.datadir)
    self.parseMetadata
  end

  return @metadata
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

#    methodcall("ZenSitemap.initialize")

    @documents = {}
    @doc_order = []

    self['title']       ||= "SiteMap"
    self['description'] ||= "This page links to every page in the website."
    self['keywords']    ||= "sitemap, website"

    count = 0

    IO.foreach(self.datapath) { |f|
#      methodcall("ZenSitemap.initialize.foreach")
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

  @@metadata = {}

=begin

--- Metadata.new(directory, toplevel = "/")

    Instantiates a new metadata object and loads the data from
    ((|directory|)) up to the ((|toplevel|)) directory.

=end

  def initialize(directory, toplevel = "/")
    super()

    self.default = nil

    unless (test(?e, directory)) then
      raise ArgumentError, "directory #{directory} does not exist"
    end

    unless (test(?d, toplevel)) then
      raise ArgumentError, "toplevel directory #{toplevel} does not exist"
    end

    # Check that toplevel is ABOVE directory, not below. Can be equal.
    abs_dir = File.expand_path(directory)
    abs_top = File.expand_path(toplevel)
    if (abs_top.length > abs_dir.length || abs_dir.index(abs_top) != 0) then
      raise ArgumentError, "toplevel is not a parent dir to directory"
    end

    if (test(?f, directory)) then
      directory = File.dirname(directory)
    end

    self.loadFromDirectory(directory, toplevel)
  end

=begin

--- Metadata#loadFromDirectory(directory, toplevel, count=1)

    Loads a series of metadata files from the directory ((|toplevel|))
    down to ((|directory|)). Each load in turn may override previous
    values.

=end

  def loadFromDirectory(directory, toplevel, count = 1)

    raise "too many recursions" if (count > 20)

    if (directory != toplevel && directory != "/" && directory != ".") then
      # Recurse to parent directory. Increment count for basic loop protection.
      self.loadFromDirectory(File.dirname(directory), toplevel, count + 1)
    end

    file = directory + "/" + "metadata.txt"
    if (test(?f, file)) then
      self.load(file)
    end

  end

=begin

--- Metadata#load(file)

    Loads a specific file ((|file|)). If any keys already exist that
    are specifed in the file, then they are overridden.

=end

  def load(file)

#    methodcall("Metadata.load")

    count = 0

    # TODO: add a caching mechanism here. This is ~25% of our time
    unless (@@metadata[file]) then
      hash = {}
      IO.foreach(file) { | line |
#	methodcall("Metadata.load.foreach")
	count += 1
	if (line =~ /^\s*(\"(?:\\.|[^\"]+)\"|[^=]+)\s*=\s*(.*?)\s*$/) then

	  # REFACTEE: this is duplicated from above
	  begin
	    key = $1
	    val = $2

	    key = eval(key)
	    val = eval(val)
	  rescue Exception
	    $stderr.puts "WARNING on line #{count}: eval failed: #{line}: #{$!}"
	  else
	    hash[key] = val
	  end
	elsif (line =~ /^\s*$/) then
	  # ignore
	elsif (line =~ /^\#.*$/) then
	  # ignore
	else
	  $stderr.puts "WARNING on line #{count}: cannot parse: #{line}"
	end
      }
      @@metadata[file] = hash
    end

    self.update(@@metadata[file])

  end

end

=begin

= Class GenericRenderer

A GenericRenderer provides an interface for all renderers. It renders
nothing itself.

=== Methods

=end

class GenericRenderer

  attr_reader :result if $TESTING

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

= Class CompositeRenderer

Allows multiple renderers to be plugged into a single renderer.

=== Methods

=end

class CompositeRenderer < GenericRenderer

=begin

--- CompositeRenderer#new(document)

    Creates a new CompositeRenderer.

=end

  def initialize(document)
    super(document)
    @renderers = []
  end

  def addRenderer(renderer)
    @renderers.push(renderer)
  end

=begin

--- CompositeRenderer#render(content)

    Renders by running all of the renderers in sequence.

=end

  def render(content)
    @renderers.each { | renderer |
      content = renderer.render(content)
    }
    return content
  end

end

=begin

= Class StandardRenderer

Creates a fairly standard webpage using several different renderers.

=== Methods

=end

class StandardRenderer < CompositeRenderer

=begin

--- StandardRenderer#new(document)

    Creates a new StandardRenderer.

=end

  def initialize(document)
    super(document)

    self.addRenderer(SubpageRenderer.new(document))
    self.addRenderer(MetadataRenderer.new(document))
    self.addRenderer(TextToHtmlRenderer.new(document))
    self.addRenderer(HtmlTemplateRenderer.new(document))
    self.addRenderer(FooterRenderer.new(document))
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

  def hash2html(hash)
    result = ""

    if (hash) then
      result += "<DL>\n"
      hash.keys.sort.each { | key |
	val = hash[key]
	result += "  <DT>#{key}</DT>\n"
	result += "  <DD>#{val}</DD>\n\n"
      }
      result += "</DL>\n"
    else
      result = "not a hash"
    end

    return result
  end

end

=begin

= Class SubpageRenderer

Generates a list of known subpages in a format compatible with
TextToHtmlRenderer.

=== Methods

=end

class SubpageRenderer < GenericRenderer

=begin

     --- SubpageRenderer#render(content)

     Renders a list of known subpages in a format compatible with
     TextToHtmlRenderer. Adds the list to the end of the content.

=end

  def render(content)
    @result = content

    subpages = @document.subpages.clone
    if (subpages.length > 0) then
      push("\n\n")
      push("** Subpages:\n\n")
      subpages.each_index { | index |
	url      = subpages[index]
	doc      = @website[url]
	title    = doc.fulltitle

	push("+ <A HREF=\"#{url}\">#{title}</A>\n")
      }
      push("\n")
    end

    return @result
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

    Metadata variables used:

    + author
    + banner - graphic at the top of the page, usually a logo
    + bgcolor - defaults to not being defined
    + copyright
    + description
    + dtd (default: 'DTD HTML 4.0 Transitional')
    + email - used in a mailto in metadata
    + keywords
    + rating (default: 'general')
    + stylesheet
    + subtitle
    + title (default: 'Unknown Title')

=end

  def render(content)
    author      = @document['author']
    banner      = @document['banner']
    bgcolor     = @document['bgcolor']
    dtd		= @document['dtd'] || 'DTD HTML 4.0 Transitional'
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
    push("<!DOCTYPE HTML PUBLIC \"-//W3C//#{dtd}//EN\">\n")
    push("<HTML>\n")
    push("<HEAD>\n")
    push("<TITLE>#{titletext}</TITLE>\n")

    push("<LINK REV=\"MADE\" HREF=\"mailto:#{email}\">\n") if email
    push("<LINK REL=\"STYLESHEET\" HREF=\"#{stylesheet}\" type=text/css title=\"#{stylesheet}\">\n") if stylesheet

    push("<META NAME=\"rating\" CONTENT=\"#{rating}\">\n")
    push("<META NAME=\"GENERATOR\" CONTENT=\"#{ZenWebsite.banner}\">\n")
    push("<META NAME=\"author\" CONTENT=\"#{author}\">\n") if author
    push("<META NAME=\"copyright\" CONTENT=\"#{copyright}\">\n") if copyright
    push("<META NAME=\"keywords\" CONTENT=\"#{keywords}\">\n") if keywords
    push("<META NAME=\"description\" CONTENT=\"#{description}\">\n") if description

    push("</HEAD>\n")
    push("<BODY" + (bgcolor ? " BGCOLOR=\"#{bgcolor}\"" : '') + ">\n")

    self.navbar

    if banner then
      push("<IMG SRC=\"#{banner}\" BORDER=0><BR>\n")
      unless (subtitle) then
	push("<H3>#{title}</H3>\n")
      end
    else
      push("<H1>#{title}</H1>\n")
    end

    push("<H2>#{subtitle}</H2>\n") if subtitle
    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    push(content)

    push("<HR SIZE=\"3\" NOSHADE>\n\n")

    self.navbar

    push("\n</BODY>\n</HTML>\n")

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

= Class MetadataRenderer

Converts all metadata references into their values.

=== Methods

=end

class MetadataRenderer < GenericRenderer

=begin

     --- MetadataRenderer#render(content)

     Converts all metadata references into their values.

=end

  def render(content)

    content=content.collect { | p |
      p.gsub!(/\#\{([^\}]+)\}/) {
	key = $1

	# check to see if this is a metadata entry
	val = @document[key] || nil
	
	# otherwise try to eval it. If that fails, just give text.
	unless (val) then
	  begin
	    val = eval(key)
	  rescue NameError
	    val = key
	  rescue Exception => err
	    $stderr.puts "eval failed in MetadataRenderer for #{@document.datapath}: #{p}."
	    val = key
	  end
	end
	
	val
      }
      p
    }

    return content
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
      p.gsub!(/\\\{/, "{")

      if (p =~ /^(\*\*+)\s*(.*)$/) then
	level = $1.length
	push("<H#{level}>#{$2}</H#{level}>\n\n")
      elsif (p =~ /^---+$/) then
	push("<HR SIZE=\"1\" NOSHADE>\n\n")
      elsif (p =~ /^===+$/) then
	push("<HR SIZE=\"2\" NOSHADE>\n\n")
      elsif (p =~ /^%[=-]/) then
	hash = @document.createHash(p)

	if (hash) then
	  push(self.hash2html(hash) + "\n")
	end
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

    # FIX: xmp makes this slow
    # put it back into line-by-line format
    # I use scan instead of split so I can keep the EOLs.
    @result = @result.join("\n").scan(/^.*[\n\r]+/)

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

      unless placed then
	unshift(header) unless placed
      end
    else
      @result = content
    end

    return @result
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
    else
      @result = content
    end

    return @result
  end
end

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

    text = content.join('')
    content = text.split(/#{$\/}#{$\/}+/)
    
    content.each { | p |

      # BUG? I think ruby has a bug, can't test for m/^\s*\!/
      if (p =~ /^[\ \t]*\!/m) then

	p.gsub!(/^[\ \t]*\!/, '')
	
	begin
	  cmd = "irb --prompt xmp --noreadline 2>/dev/null"
	  puts "Running irb for code:"
	  puts p
	  IO.popen(cmd, "r+") { |xmp|
	    p.split(/\n/).each { |line|
	      push("  #{line}")
	      if line !~ /^\s+\#/ then
		xmp.puts(line)
		s = xmp.gets.chomp!
		s.sub!(/==>(.*)$/, '==\\><EM>\1</EM>')
		push("    #{s}")
	      end
	    }
	  }
	rescue Exception => something
	  $stderr.puts "xmp: #{something}\nTrace =\n#{$@.join(\"\n\")}\n"
	end
      else
	push(p)
      end
      push("\n\n")
    }
    
    # put it back into line-by-line format
    @result = @result.join("\n").scan(/^.*[\n\r]+/)

    return @result
  end
end

############################################################
# Main:

if __FILE__ == $0

  puts ZenWebsite.banner() unless $TESTING

  if (ARGV.size == 2) then
    path = ARGV.shift
    url  = ARGV.shift
  elsif (ARGV.size == 1) then
    path = ARGV.shift || raise(ArgumentError, "Need a sitemap path to load.")
    url  = "/SiteMap.html"
  else
    raise(ArgumentError, "Usage: #{$0} datadir [sitemapurl]")
  end

  ZenWebsite.new(url, path, path + "html").renderSite()

end


=begin

= Class XXXRenderer

YYY

=== Methods

=end

class XXXRenderer < GenericRenderer

=begin

     --- XXXRenderer#render(content)

     YYY

=end

  def render(content)
    # YYY
    return @result
  end

end

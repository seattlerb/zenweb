#!/usr/local/bin/ruby -w

############################################################
# Old timings are at the end of this file
############################################################
# New render(string)->string architecture
############################################################
# %   cumulative   self              self     total
# time   seconds   seconds    calls  ms/call  ms/call  name
# 13.61    11.70     11.70     1533     7.63   176.06  Array#each
# 12.77    22.66     10.97      235    46.68    69.88  IO#foreach
# 12.51    33.41     10.75    14955     0.72     1.08  GenericRenderer#push
#  5.78    38.38      4.97      355    14.00    31.43  ZenDocument#createList
#  4.39    42.16      3.77    35405     0.11     0.11  Array#push
#
# real	1m39.577s
# user	1m27.635s
# sys	0m7.733s
############################################################
# Previous render(Array)->Array architecture
############################################################
#   %   cumulative   self              self     total
#  time   seconds   seconds    calls  ms/call  ms/call  name
#  26.83    27.75     27.75    61960     0.45     0.89  GenericRenderer#push
#  15.06    43.33     15.58     2059     7.57   164.09  Array#each
#   9.67    53.33     10.00      235    42.55    62.00  IO#foreach
#   5.89    59.42      6.09    82184     0.07     0.07  Array#push
#   4.74    64.32      4.90    64417     0.08     0.08  Kernel.is_a?
#
# real    2m1.142s
# user    1m44.934s
# sys     0m12.849s
############################################################

require 'cgi'
require 'ftools'
require 'uri'

$TESTING = FALSE unless defined? $TESTING

# this is due to a stupid bug across 1.6.4, 1.6.7, and 1.7.2.
$PARAGRAPH_RE = Regexp.new( $/ * 2 + "+")
$PARAGRAPH_END_RE = Regexp.new( "^" + $/ + "+")

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

And many renderer classes, now located separately in the ZenWeb
sub-directory. For example:

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

  VERSION = '2.13.0'

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
    force = false
    unless (test(?d, self.htmldir)) then
      File::makedirs(self.htmldir)
    else
      # NOTE: It would be better to know what was changed and only
      # rerender them and their previous and current immediate
      # relatives.

      # HACK: found a bug at the last minute. Looks minor, but I'm
      # disabling this in case it's too annoying.
      # force = self.sitemap.newerThanTarget
    end

    if force then
      puts "Sitemap modified, regenerating entire website." unless $TESTING
    end

    @doc_order.each { | url |
      doc = @documents[url]

      if doc.render(force) then
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
    return "ZenWeb v. #{ZenWebsite::VERSION} http://www.zenspider.com/ZSS/Products/ZenWeb/"
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
    @content  = ""

    unless (test(?f, self.datapath)) then
      raise ArgumentError, "url #{url} doesn't exist in #{self.datadir} (#{self.datapath})"
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

    page = []

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
	page.push(line)
      end
    }

    @content = page.join('')
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

      # 4.1) Invoke a renderer by that name

      renderer = nil
      begin

	# try to find ZenWeb/blah.rb first, then just blah.rb.
	begin
	  require "ZenWeb/#{rendererName}"
	rescue LoadError => loaderr
	  require "#{rendererName}" # FIX: ruby requires the quotes?!?!
	end 

	theClass = Module.const_get(rendererName)
	renderer = theClass.send("new", self)
      rescue LoadError, NameError => err
	raise NotImplementedError, "Renderer #{rendererName} is not implemented or loaded (#{err})"
      end

      # 4.2) Pass entire file contents to renderer and replace w/ result.
      newresult = renderer.render(result)
      result = newresult
    }

    return result
  end

=begin

--- ZenDocument#render(force)

    Gets the rendered content from ((<ZenDocument#renderContent>)) and
    writes it to disk if it decides to or is told to force the
    rendering. Returns true if it rendered the document.

=end

  def render(force=false)
    if force or self.newerThanTarget then
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

    count = 0

    unless (@@metadata[file]) then
      hash = {}
      IO.foreach(file) { | line |
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


#!/usr/local/bin/ruby -w

require 'ftools' # for File::* below

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

  VERSION = '2.17.0'

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

      doc.render(force)
    }

    self
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

  def top
    self[@doc_order.first]
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

  # 1.8 has a bug in it that causes MASSIVE slowdown with cyclic
  # object graphs. The fix has been submitted, but won't be released
  # until 1.8.2 or above. This is a hacky workaround that makes
  # running tolerable. I should come up with a better solution to deal
  # with debugging, but I haven't actually needed to debug in a while.
  # Basically, avoid ever showing the website or sitemap in an inspect.

  if false and VERSION =~ /^1\.8/ then
    def inspect
      return "<#{self.class}\@#{self.object_id}: #{self.url}>"
    end
  end

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

    # FIX this is mainly here to force the rendering of the metadata,
    # which also forces the population of @content.
    title = self['title']

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
    if force or self['force'] or self.newerThanTarget then

      puts url unless $TESTING

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
    self.url.sub(/\/[^\/]+\/index.html$/, "/index.html").sub(/\/[^\/]+$/, "/index.html")
  end

=begin

--- ZenDocument#addSubpage

    Adds a url to the list of subpages of this document.

=end

  def addSubpage(url)
    raise ArgumentError, "url must be a string" unless url.instance_of? String 
    if (url != self.url) then
      self.subpages.push(url)
    end
  end

  ############################################################
  # Accessors:

=begin

--- ZenDocument#parent

    Returns the document object corresponding to the parentURL or
    itself if it IS the top.

=end

  def parent
    parentURL = self.parentURL
    parent = (parentURL != self.url ? self.website[parentURL] : self)
    parent = self if parent.nil?

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
    title = self.title
    subtitle = self['subtitle'] || nil

    return title + (subtitle ? ": " + subtitle : '')
  end

  def title
    self['title'] || "Unknown"
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

=begin

--- ZenDocument#metadata

    DOC

=end

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

  RESERVED_WORDS=Regexp.new("\`|" + %w(author banner bgcolor copyright description dtd email keywords rating stylesheet subtitle title charset force header footer style include icbm icbm_title).join("|"))

  @@metadata = {}
  @@count = {}
  @@count.default = 0

=begin

--- Metadata#displayBadMetadata

    Reports both unused metadata (only really good if you render the
    entire site) and metadata accessed but not defined (sometimes gets
    confused by legit ruby code).

=end

  def self.displayBadMetadata

    good_key = {}

    puts
    puts "Unused metadata entries:"
    puts
    @@metadata.each do |file, metadata|
      puts "File = #{file}"
      metadata.each_key do |key|
	count = @@count[key]
	good_key[key] = true
	puts "  #{key}" unless count > 0
      end
    end

    puts
    puts "Bad accesses:"
    puts
    @@count.each do |key, count|
      puts "  #{key}: #{count}" unless good_key[key] or key =~ RESERVED_WORDS
    end
  end

  def [](key)
    @@count[key] += 1
    $stderr.puts "  WARNING: metadata '#{key}' does not exist" unless $TESTING or key?(key) or key =~ RESERVED_WORDS
    super
  end

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
# Object methods - shortcuts for users

=begin

--- link(url, title)

    Returns a string with an anchor with the appropriate data.

=end

def link(url, title)
  return "<A HREF=\"#{url}\">#{title}</A>"
end

=begin

--- img(url, alt, height=0, width=0, border=0)

    Returns a string with an image tag with the appropriate data.

=end

def img(url, alt, height=nil, width=nil, border=0)
  return "<IMG SRC=\"#{url}\" ALT=\"#{alt}\" BORDER=#{border}" +(height ? " HEIGHT=#{height}" : '')+(width ? " WIDTH=#{width}" : '')+">"
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

  if path == "data" then
    dest = "html"
  else
    dest = path + "html"
  end

  dirty = test ?d, dest

  ZenWebsite.new(url, path, dest).renderSite
  Metadata.displayBadMetadata unless dirty

end

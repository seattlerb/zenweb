#!/usr/local/bin/ruby -w

# TODO: write a simple requirements doc
# TODO: get rubyunit tests in place NOW
# TODO: generalize/modularize the metadata scanning code
# TODO: set up a metadata dictionary structure w/ parent refs
# TODO: evaluate eruby for text processing
# TODO: get webpage scanning code done asap
# TODO: compensate for tabbed urls
#
# Two types of designs that I can think of:
#
# 1) Every page is created in a generic Page instance. Each page
#    knows to either use a generic renderer, or to use a customized 
#    renderer per metadata specification. Customized renderer could
#    be generic + decorators, or could be a completely different 
#    engine (or could be a shell program?)
#
# 2) The sitemap picks the page type and creates an instance of it
#    directly. That instance's class must know how to render.


=begin
A ZenWebsite is a collection of pages, one of which is a sitemap
that knows the order and hierarchy of those pages.
=end

class ZenWebsite

  def initialize(sitemapUrl, datadir, htmldir)

    @datadir = datadir
    @htmldir = htmldir
    @sitemap = ZenSitemap.new(sitemapUrl, datadir, htmldir)

  end

  def renderSite()

    #1) Open Sitemap:
    #  1) Read all urls:
    #    1) Find page corresponding to url.
    #    2) Open file.
    #    3) Parse file, extracting metadata and content.
    #    4) Based on current metadata, instantiate the correct type of page.
    #2) Generate a makefile OR dependency map.
    #3) Run make OR iterate over each page instance and IF it should
    #   be generated, generate it.
    
    @documents = @sitemap.getDocuments

    @documents.each_value { | doc |
      doc.render()
    }

  end

end

=begin
A ZenDocument is an object representing a unit of input data,
typically a file. It may correspond to multiple output data (one
document could create several HTML pages).
=end

class ZenDocument

=begin
There are 3 different types of relationships in a document. Parent,
Child, Sibling.
=end

  def initialize(url, datadir, htmldir)
    puts "ZenDocument.initialize"

    @url = url
    @datadir = datadir
    @htmldir = htmldir

    @path = nil
  end

  def render()
    puts "Rendering #{@url} from #{self.getPath}"
    # TODO plug in generic rendering/chain mechanism
  end

  def getPath()

    if (@path.nil?) then
      @path = "#{@datadir}#{@url}"
      @path.sub!(/\.html$/, "")
      @path.sub!(/~/, "")
    end

    return @path
  end

end

=begin

A ZenSitemap is a ZenDocument that knows about the order and hierarchy
of all of the other pages in the website.

TODO: how much difference is there between a website and a sitemap?

=end

class ZenSitemap < ZenDocument

  def initialize(url, datadir, htmldir)
    super(url, datadir, htmldir)

    puts "ZenSitemap.initialize"

    @documents = {}
    sitemap = self.getPath

    if (! defined? sitemap or sitemap.nil?) then
      raise ArgumentError, "Need a sitemap argument"
    end

    unless (test(?f, sitemap)) then
      puts "Sitemap '#{sitemap}' does not exist"
      exit 1
    end

    IO.foreach(sitemap) { |f|
      f.chomp!

      # general syntax:
      #   ^\s*#.*		comment
      #   ^\s*\w+\s*=\s*(FIX)   metadata      DIE
      #   ^\s*[/\w-_~]+		url
      # TODO: we may want to extend the url+ spec to just parse metadata

      f.gsub!(/\s*\#.*/, '')
      f.gsub!(/^\s+/, '')
      f.gsub!(/\s+$/, '')

      next if f == ""

      if (f =~ /^\s*(\w+)\s*=\s*(.*)/) then
	@metadata[$1] = $2
      elsif f =~ /^\s*([\/-_~\.\w]+)$/
	# FIX: this doesn't make much sense for the sitemap itself.
	#      seems like a bad design.
	@documents[$1] = ZenDocument.new($1, @datadir, @htmldir)
      else
	puts "Warning: unknown type of line '#{f}'"
      end
    }

    @datadir = "" # can default, but also available in metadata
    @htmldir = "" # can default, but also available in metadata

  end # initialize

  # FIX: switch to normal getter
  def getDocuments()
    return @documents
  end

end

if __FILE__ == $0
  if (ARGV.length > 0) then
    ZenWebsite.new("/SiteMap.html", "test", "testhtml").renderSite()
  else
    raise "Need a sitemap path to load."
  end
end

# module HasMetadata
#   def scanMetadata()
#       # general syntax:
#       #   ^\s*#.*		comment
#       #   ^\s*\w+\s*=\s*(FIX)   metadata      DIE
#       #   ^\s*[/\w-_~]+		url
#       # TODO: we may want to extend the url+ spec to just parse metadata
#       f.gsub!(/\s*\#.*/, '')
#       f.gsub!(/^\s+/, '')
#       f.gsub!(/\s+$/, '')
#       next if f == ""
#       if (f =~ /^\s*(\w+)\s*=\s*(.*)/) then
# 	@metadata[$1] = $2
#       elsif f =~ /^\s*([\/-_~\.\w]+)$/
# 	@documents[$1] = Page.new($1)
#       else
# 	puts "Warning: unknown type of line '#{f}'"
#       end
#   end
# end


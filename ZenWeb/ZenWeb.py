#!/bin/env python
# ZenWeb.py
# COPYRIGHT (C) 1997-1998 Ryan Davis, Zen Spider Software
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and
# that both that copyright notice and this permission notice appear in
# supporting documentation.
# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
# SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS, IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
# CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""

	An extension of HTMLGen 2.0 to provide site oriented HTML
	generation.  ZenWeb is based on the notion of a sitemap, which
	defines a hierarchial multipage website. It defines a class
	called ZenWebsite which defines the website as a whole,
	ZenDocument which represents a regular page in ZenWebsite, and
	two specializations SiteMap and RawDocument.

"""

from HTMLgen import SimpleDocument, mpath, Heading, RawText, List, Paragraph, SeriesDocument, DOCTYPE, Href, HR, Pre, Image
from ZSSUtil import fileIsNewerThan, myopen, createList, makedirs
from sys import exit
import HTMLcolors
import HTMLgen # for __version__
import os
import posixpath
import regsub
import regex
import re
import string

__version__	 = '1.2.1'

class ZenWebsite:
	""" Defines a website and manages the pages in that website based on a sitemap.
	"""

	def __init__(self, sitemap, input, output):
		""" + Read a sitemap file and create an array of URLS.
			+ Create a dictionary of URL/Document type instance pairs.
			+ Plug each document object with proper next/prev/parent values.
			+ Tell all pages to render.
		"""
				
		self.datadir	= input
		self.htmldir	= output
		self.homeIMG 	= ('/image/buttons/on/home.gif', 60, 15)
		self.navhelpIMG = ('/image/buttons/on/navhelp.gif', 60, 15)
		self.nextIMG 	= ('/image/buttons/on/nextpage.gif', 60, 15)
		self.parentIMG  = ('/image/buttons/on/up.gif', 60, 15)
		self.prevIMG	= ('/image/buttons/on/prevpage.gif', 60, 15)
		self.sitemapIMG	= ('/image/buttons/on/sitemap.gif', 60, 15)
		self.searchIMG	= ('/image/buttons/on/search.gif', 60, 15)
		if not self.__dict__.has_key("defaultType"):
			self.defaultType	= "ZenDocument"

		self.siteMapInput = posixpath.join(self.datadir, sitemap)
		self.siteMapOutput = posixpath.join(self.htmldir, sitemap + ".html")
		self.siteMapIsModified = fileIsNewerThan(mpath(self.siteMapInput), mpath(self.siteMapOutput))

		self.pages = {}
		self.sitemap = []
		self.glossary = {}

		# constraint: path cannot contain "#"
		re_sitemap = regex.compile("^\([^\#\t\ ]+\)[\t\ ]*\(.*\)$")

		# instantiate
		previousPage = None
		for URL in map(lambda path: regsub.sub("\012$", "", path), myopen(self.siteMapInput).readlines()):
			pageType = self.defaultType
			if (re_sitemap.search(URL) > -1):
				if re_sitemap.group(2):
					URL = re_sitemap.group(1)
					pageType = re_sitemap.group(2)
			else: # assume that it was a #decl or blank line
				continue

			theClass = None
			try:
				import __main__
				if __main__.__dict__.has_key(pageType) and not globals().has_key(pageType):
					globals()[pageType] = __main__.__dict__[pageType]
				theClass = eval(pageType)
			except SyntaxError, err:
				print str(err) + ": 1 " + str(theClass) + ". BYPASSING ERROR"
				theClass = ZenDocument
			except NameError, err:
				keys = globals().keys()
				keys.sort()
				print "Couldn't find %s in %s" % (pageType, str(keys))
				import sys
				sys.exit(1)
			
			doc = None
			try:
				doc = theClass(self, URL, previousPage)
			except TypeError, err:
				print str(err) + ": 2 " + str(theClass) + ". BYPASSING ERROR"
				doc = ZenDocument(self, URL, previousPage)

			self.pages[URL] = doc
			self.sitemap.append(URL)
			previousPage = doc

		self.homeURL			= 'URL'
		self.home_pg			= self.pageAtURL('/index.html')
		self.sitemap_pg			= self.pageAtURL('/%s.html' % sitemap)

	def pageAtURL(self, url):
		""" Returns the document object for url or None if invalid url or not yet initialized. """
		result = None
		if type(url) == type("blah"):
			try:
				result = self.pages[url]
			except KeyError: None # ignore this one
		return result
	
	def renderSite(self):
		""" Renders pages in sitemap that have changed since last run OR all pages
			if the sitemap has changed or needs rendering.
		"""
		print "Reading and caching all documents"
		self.readAllPages()
		self.sitemap_pg.contents = []
		print "Writing those documents that have changed"
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			input = regsub.sub("\.html$", "", regsub.sub("^/", "", url))

			if (input[0] == "/"):
				input = input[1:]

			input = posixpath.join(self.datadir, input)
			input = regsub.sub("~", "", input)

			output = url
			if (output[0] == "/"):
				output = output[1:]

			output = posixpath.join(self.htmldir, output)
			output = regsub.sub("~", "", output)

			# if you want to do the whole site when the sitemap
			# is modified, add 'self.siteMapIsModified' to logic
			if not fileIsNewerThan(mpath(output), mpath(input)):
				print "%s" % (output)
				doc	= self.pages[url]
				doc.read(input)
				doc.write(output)

	def printSiteMap(self):
		""" Prints a list of all URLs in sitemap. """
		import string
		print string.joinfields(self.sitemap, "\n")
	
	def readAllPages(self):
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			input = regsub.sub("\.html$", "", regsub.sub("^/", "", url))
			if (input[0] == "/"):
				input = input[1:]
			input = posixpath.join(self.datadir, input)
			if (input <> ""):
				doc	= self.pages[url]
				doc.read(input)
	
	def titles(self):
		""" Returns a dictionary containing URL->title pairs.
		"""
		self.readAllPages()
		result = {}
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			doc	= self.pages[url]
			if doc.subtitle:
				result[doc.url] = "%s: %s" % (doc.title, doc.subtitle)
			else:
				result[doc.url] = doc.title
		return result
		
	def fulltitles(self):
		""" Returns a dictionary containing URL->title pairs. If the page has a 
			subtitle that is appended to the title.
		"""
		self.readAllPages()
		result = {}
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			doc	= self.pages[url]
			if doc.subtitle:
				result[doc.url] = "%s: %s" % (doc.title, doc.subtitle)
			else:
				result[doc.url] = doc.title
		return result
		
	def keywords(self):
		""" Returns a dictionary containing URL->keyword pairs.
		"""
		self.readAllPages()
		result = {}
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			doc	= self.pages[url]
			result[doc.url] = doc.keywords
		return result
		
	def descriptions(self):
		""" Returns a dictionary containing URL->description pairs.
		"""
		self.readAllPages()
		result = {}
		max = len(self.sitemap)
		for i in range(0, max):
			url = self.sitemap[i]
			doc	= self.pages[url]
			result[doc.url] = doc.description
		return result
		
class ZenDocument(SimpleDocument):
	""" A Document specification that conforms to the ZSS Website standards.
		Version 2.0. This extends SimpleDocument to define a more site oriented 
		webpage than SimpleDocument does. It provides a page that not only has
		SimpleDocument's standard navigation tools (slightly reworded), but also
		defines navigation tools such as parent, sitemap, navhelp, and links to all
		subpages. It also is more search engine friendly in that it defines meta
		keyword and description entries.
		
		Finally, and probably most important, ZenDocument allows the page to be defined
		in regular engligh paragraph format with easy to use and (hopefully) extendable
		markup embellishments. This allows the user to not need to deal with HTML
		until specific features are needed.
	"""
	def __init__(self, website, url, prevp=None, nextp=None, **kw):
		apply(SimpleDocument.__init__, (self, None,), kw)

		self.website		= website
		self.url		= url
		self.prevpage		= prevp
		self.nextpage		= nextp
		
		# Don't Customize (unless you really want to of course)
		self.bgcolor		= HTMLcolors.WHITE
		self.textcolor		= HTMLcolors.BLACK
		self.title		= "UNTITLED!!! CHANGE THIS"
		self.banner		= None
		self.subtitle		= None
		self.metadict		= {}
		self.keywords		= None
		self.description	= None
		self.place_nav_bar	= 'yes'
		self.glossary		= self.website.glossary

		# Customize
		self.author		= 'AUTHOR'
		self.email		= 'AUTHOR@EMAIL'
		self.sitename		= 'SITE NAME'
		self.background		= None

		######################################################################
		## Navigation

		self.navhelp		= None
		self.parent		= None
		self.sitemap		= None
		self.subpages		= None
		self.includesubpages	= 1
		self.parent		= self.website.pageAtURL(self.parentOfURL(self.url))

		self.fileInput=0

		if (self.prevpage is not None):
			self.prevpage.nextpage = self
		
		if (self.parent is not None):
			self.parent.addSubpage(self)

	def loadRCs(self, filename="HTML.rc", path=""):
		" to be called by read "
		
		assert path <> "", "path argument shall not be empty"

		if (os.path.isfile(mpath(path))):
			path = posixpath.dirname(path)
			
		if (path <> self.website.datadir):
			#recurse until st top, then unwind.
			self.loadRCs(filename, posixpath.dirname(path))
		target = mpath(posixpath.join(path, filename))
		if (os.path.exists(target)):
			execfile(target, self.__dict__)

	def addMeta(self, key, value):
		self.metadict[key] = value

	def getTitle(self):
		return self.title

	def addSubpage(self, subpage):
		if self.subpages is None:
			self.subpages = []
		self.subpages.append(subpage) 

	def __str__(self):
		s = []
		if self.cgi:
			s.append(CONTYPE + DOCTYPE)
		else:
			s.append(DOCTYPE)
		# build the HEAD and BODY tags
		s.append(self.html_head())
		s.append(self.html_body_tag())

		# HEADER SECTION
		s.append(self.header())
		
		# DOCUMENT CONTENT SECTION
		bodystring = '%s\n' * len(self.contents)
				
		# Glossary lookup code, stolen from HTMLgen's TemplateDocument
		# and modified considerably.

		subpat = re.compile(r"{[^}]+}")
		source = bodystring % tuple(self.contents)

		i = 0
		output = []
		matched = subpat.search(source[i:])
		while matched:
			a, b = matched.span()
			output.append(source[i:i+a])
			# using the new get method for dicts in 1.5
			key = source[i+a+1:i+b-1]
			alt = "{" + key + "}"
			
			value = self.glossary.get(key)

			if value == alt:
				print "WARNING Couldn't find glossary entry for '%s'" % (key)
			else:
				output.append(str(self.glossary.get(key, alt)))

			i = i + b
			matched = subpat.search(source[i:])
		else:
			output.append(source[i:])
		
		result = string.join(output, '')

		s.append(result)

		# FOOTER SECTION
		s.append(self.footer())
		s.append(self.html_foot())
		return string.join(s, '')

	def html_head(self):
		"""Generate the HEAD TITLE and BODY tags.
		"""
		s = []
		
		s.append('<HTML>\n<HEAD>\n')

		if self.subtitle:
			s.append('\t<TITLE>%s: %s</TITLE>\n' % (self.title, self.subtitle))
		else:
			s.append('\t<TITLE>%s</TITLE>\n' % self.title)

		s.append('\t<LINK REV=MADE HREF="mailto:%s">\n' % (self.email))

		if self.keywords:
			self.addMeta("keywords", self.keywords)
		if self.description:
			self.addMeta("description", self.description)

		self.addMeta("GENERATOR", "HTMLGen %s and ZenWeb %s" % (HTMLgen.__version__, __version__))
		self.addMeta("copyright", "Copyright 1997-1998 by %s" % self.author)
		self.addMeta("rating", "general")
		self.addMeta("author", "%s" % self.author)

		if self.metadict and len(self.metadict) > 0:
			for (key, value) in self.metadict.items():
				s.append('\t<META NAME="%s" CONTENT="%s">\n' % (key, value))

		if self.meta: s.append(str(self.meta)) # DEPRECATE
		if self.base: s.append(str(self.base))
		if self.stylesheet:
			s.append('\n\t<LINK rel=stylesheet href="%s" type=text/css title="%s">\n' \
					 % (self.stylesheet, self.stylesheet))
		if self.style:
			s.append('\n\t<STYLE>\n<!--\n%s\n-->\n</style>\n' % self.style)
		if self.script: # for javascripts
			if type(self.script) in (TupleType, ListType):
				for script in self.script:
					s.append(str(script))
			else:
				s.append(str(self.script))
		s.append('\n</HEAD>\n')
		return string.join(s, '')
	
	def html_foot(self):
		return '\n</BODY>\n</HTML>\n' # CLOSE the document


	def header(self):
		"""Generate the standard header markups.
		"""
		# HEADER SECTION - overload this if you don't like mine.
		s = ['']
 		if self.banner:
 			bannertype = type(self.banner)
 			if bannertype in (TupleType, StringType):
 				s.append(str(Image(self.banner, border=0)) + '<BR>\n')
 			elif bannertype == InstanceType:
 				s.append(str(self.banner) + '<BR>\n')
 			else:
 				raise TypeError, 'banner must be either a tuple, instance, or string.'
 		if self.place_nav_bar:
 			s.append(self.nav_bar())

 		s.append(str(Heading(1, RawText(self.title))))

 		if self.subtitle:
 			s.append(str(Heading(2, self.subtitle)))
 		s.append(str(self.standardBigRule()) + "\n")
		return string.join(s, '')

	def footer(self):
		"""Generate the standard footer markups.
		"""

		s =	['']
		if self.subpages is not None and self.includesubpages == 1:
			theList = List()
			s.append(str(Heading(2, "Subpages:")))
			for subpage in self.subpages:
				theList.append(Href(subpage.url, subpage.getTitle()))
			s.append(str(theList))

		s.append(str(self.standardBigRule()) + "\n")

		if self.place_nav_bar:
 			s.append(self.nav_bar())
		
		return string.join(s, '')

	def standardBigRule(self):
		"""	A thick rule, size = 3, no shading, centered. """
		return HR(align="CENTER", noshade=None, size="3")

	def standardMediumRule(self):
		"""	A medium rule, size = 2, no shading, centered. """
		return HR(align="CENTER", noshade=None, size="2")

	def standardSmallRule(self):
		"""	A skinny rule, size = 1, no shading, centered. """
		return HR(align="CENTER", noshade=None, size="1")

	def nav_bar(self):
		"""Generate hyperlinked navigation buttons.

		If a self.*URL attribute is null that corresponding button is
		replaced with a blank gif to properly space the remaining
		buttons.
		"""
		
		s = []

		s.append(self.mungeButton(Image(self.website.prevIMG, border=0, alt='Previous'), self.prevpage))
		s.append(self.mungeButton(Image(self.website.sitemapIMG, border=0, alt='SiteMap'), self.website.sitemap_pg))
		s.append(self.mungeButton(Image(self.website.nextIMG, border=0, alt='Next'), self.nextpage))
		s.append("<BR>\n")
		s.append(self.mungeButton(Image(self.website.parentIMG, border=0, alt='Up'), self.parent))
		s.append(self.mungeButton(Image(self.website.homeIMG, border=0, alt='Home Page'), self.website.homeURL))

		return str(Paragraph(RawText(string.join(s, '')), align='center'))

	def read(self, input):

		if self.fileInput:
			return
		self.fileInput=1

		self.loadRCs("HTML.rc", input)

		re_rule		= regex.compile('^\(--+\|==+\)$')
		re_head		= regex.compile('^\(\*\*+\)[ \t]*\(.*\)$')
		re_var		= regex.compile('^\#\([a-zA-Z_-]+\)[\ \t]+\(.*\)$')
		re_mail		= regex.compile('\([a-zA-Z_\.\-]+\@[a-zA-Z_\.\-]+\)')
		re_http		= regex.compile('[^"]\(http://[^ ]+\)')
		re_list		= regex.compile('^\(\t*\)\+[\ \t]*\(.*\)')
		re_code		= regex.compile('^<PRE>$')
		re_code_end	= regex.compile('^<\/PRE>$')

		str = ""
		try:
			str = myopen(input).read()
		except IOError, io:
			self.title = "Error"
			self.append("Error: Couldn't open %s" % (input))
			return
		
		pdata = []
		ldata = []
		
		lines = regsub.split(str, '\n')
		max = len(lines)
		index = 0
		while (index < max):
			line = lines[index]
			#print "line = '%s'" % line
			index = index + 1
			if not line:
				# print "STATE = not line"
				if pdata and ldata:
					self.append(Paragraph("Error: both pdata and ldata exist!"))
				if pdata:
					self.append(Paragraph(RawText(string.joinfields(pdata, " "))))
					pdata = []
				if ldata:
					newlist = List(createList(ldata))
					self.append(newlist)
					ldata = []
			elif re_var.search(line) > -1:
				# print "STATE = VAR"
				# Read "#var value" and set instance variable <var> to value
				if re_var.group(2) == "None":
					self.__dict__[re_var.group(1)] = None
				else:
					self.__dict__[re_var.group(1)] = re_var.group(2)
			elif re_rule.search(line) > -1:
				# print "STATE = RULE"
				# Read "--+" or "==+" and translate into HR
				self.append(HR())
			elif re_head.search(line) > -1:
				# print "STATE = HEAD"
				# Read "**** text" and translate text into H4
				level = len(re_head.group(1))
				self.append(Heading(level, RawText(re_head.group(2))))
			elif re_list.search(line) > -1:
				# print "STATE = LIST"
				ldata.append(re_list.group(1) + re_list.group(2))
			elif re_code.search(line) > -1:
				# print "STATE = CODE"
				old_index = index # incremented from above, this is desired
				while (index < max and not (re_code_end.search(lines[index]) > -1)):
					index = index + 1
				code = string.joinfields(lines[old_index:index - 1], '\n')
				self.append(Pre(code))
				index = index + 1
			else:
				# print "STATE = ELSE"
				pdata.append(line)
		if pdata and ldata:
			self.append(Paragraph("Error: both pdata and ldata exist!"))
		if pdata:
			#print "data = '%s'" % Paragraph(RawText(string.joinfields(pdata, " ")))
			self.append(Paragraph(RawText(string.joinfields(pdata, " "))))
			pdata = []
		if ldata:
			newlist = List(createList(ldata))
			self.append(newlist)
			ldata = []

	def write(self, output):
		if (output[0] == "/"):
			output = output[1:]
		try:
			SeriesDocument.write(self, output)
		except IOError, io:
			makedirs(mpath(output), 1)
			SeriesDocument.write(self, output)

	def parentOfURL(self, url):
		url = regsub.sub("/[^/]+/index.html$", "/index.html", url)
		url = regsub.sub("/[^/]+$", "/index.html", url)
		return url
	
	def mungeButton(self, button, page=None):
		""" Alters a button to appropriately display on or off based on the page.
		"""
		button = str(button)
		if page is None:
			# page doesn't exist, turn off and don't create HREF link.
			button = regsub.sub("/on/", "/off/", button)
		elif type(page) == type("blah"):
			button = str(Href(page, button))
		else:
			button = str(Href(page.url, button))
		return button + '\n'
			
class AbsSiteMap:
	""" An abstract class that defines how to read and parse a SiteMap.
		See SiteMap for an example of using this as a mixin class in your site.
	"""
	def read(self, input):

		re_var = regex.compile('^\#\([a-zA-Z_-]+\)[\ \t]+\(.*\)$')

		self.title = "SiteMap"
		self.description = "This page links to every page in the website."
		self.keywords = "sitemap, website"

		sitemap=map(self.createURL, self.website.sitemap)
		self.subtitle = "There are %d pages in this website." % len(sitemap)

		sitemap=createList(sitemap)
		sitemap=[str(Href("/index.html", "Home")), sitemap[1:] ]
		sitemap=List(sitemap)
		self.append(sitemap)

	def createURL(self, path):
		
		# strip the optional document class "a b" -> "a"
		path = self.siteMapConverter(path)
		# create the name "/a/b/c.html" -> "c"
		name = regsub.sub("\.html$", "", path)
		name = regsub.sub("/index$", "", name)
		name = regsub.sub("^/", "", name)
		# indent with tabs for each directory level, this is for createList
		name = regsub.gsub("[^/]+/", "\t", name)
		# regex it to break the tabs from the name apart
		re_indent = regex.compile("\(\t*\)\(.*\)")
		re_indent.search(name)
		return re_indent.group(1) + str(Href(path, self.website.pageAtURL(path).getTitle()))

	def siteMapConverter(self, item):
		re_sitemap = regex.compile("^\([^\t\ ]+\)[\t\ ]*\(.*\)$")
		if re_sitemap.search(item) > -1:
			return re_sitemap.group(1)
		else:
			return item

class SiteMap(AbsSiteMap, ZenDocument):
	""" Glues AbsSiteMap to ZenDocument """
	None

class AbsRawDocument:
	""" An abstract class that defines how to read and parse a RawDocument.
		See RawDocument for an example of using this as a mixin class in your site.
	"""
	def read(self, input):

		if self.fileInput:
			return
		self.fileInput = 1

		re_var = regex.compile('^\#\([a-zA-Z_-]+\)[\ \t]+\(.*\)$')

		s = ""
		try:
			s = myopen(input).read()
		except IOError, io:
			self.title = "Error"
			self.append("Error: Couldn't open %s" % (input))
			return
		
		text = ''
		for line in regsub.split(s, '\n'):
			if re_var.search(line) > -1:
				# Read "#var value" and set instance variable <var> to value
				if re_var.group(2) == "None":
					self.__dict__[re_var.group(1)] = None
				else:
					self.__dict__[re_var.group(1)] = re_var.group(2)
			else:
				text = text + line + "\n"
		self.append(str(RawText(text)))

class RawDocument(AbsRawDocument, ZenDocument):
	""" Glues AbsRawDocument to ZenDocument """
	None

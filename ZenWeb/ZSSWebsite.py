#!/bin/env python

from HTMLgen import Image, Small, BR, Href, RawText, MailTo, Paragraph
import time
import string
from ZenWeb import ZenWebsite, ZenDocument, AbsSiteMap, AbsRawDocument

class ZSSWebsite(ZenWebsite):
	""" Defines my public website
	"""

	def __init__(self, file, input, output):

		self.defaultType = "ZSSDocument"
		ZenWebsite.__init__(self, file, input, output)
		self.homeURL	= 'http://www.ZenSpider.com/'
		self.navhelp_pg	= self.pageAtURL('/NavHelp.html')
		self.search_pg	= self.pageAtURL('/Search.html')

class PrivateSite(ZSSWebsite):
	""" Defines my private website.
	"""

	def __init__(self, file, input, output):
		self.defaultType = "ZSSDocument"
		ZenWebsite.__init__(self, file, input, output)
		self.navhelp_pg	= self.pageAtURL('/private/NavHelp.html')
		self.search_pg	= self.pageAtURL('/private/Search.html')

class DemoSite(ZenWebsite):
	""" Defines a demonstration website.
	"""

	def __init__(self, file, input, output):

		ZenWebsite.__init__(self, file, input, output)
		self.homeURL	= 'http://1.1.1.1/' # A fake URL, you can substitute anything.

class ZSSDocument(ZenDocument):
	
	def __init__(self, website, url, prevp=None, nextp=None, **kw):

		apply(ZenDocument.__init__, (self, website, url, prevp, nextp), kw)
		self.author		= 'Ryan Davis'
		self.email		= 'zss@ZenSpider.com'
		self.sitename	= 'Zen Spider Software'
#		self.background	= "/image/backgrounds/normal.gif"

#	def html_body_tag(self):
#		return ZenDocument.html_body_tag(self) + '<BLOCKQUOTE>\n'
#
#	def html_foot(self):
#		return '</BLOCKQUOTE>\n' + ZenDocument.html_foot(self)
		
	def nav_buttons(self):
		"""Generate hyperlinked navigation buttons.

		If a self.*URL attribute is null that corresponding button is
		replaced with a blank gif to properly space the remaining
		buttons.
		"""
		
		s = []

		s.append(self.mungeButton(Image(self.website.prevIMG, border=0, alt='Previous'), self.prevpage))
		s.append(self.mungeButton(Image(self.website.parentIMG, border=0, alt='Up'), self.parent))
		s.append(self.mungeButton(Image(self.website.homeIMG, border=0, alt='Home Page'), self.website.homeURL))
		s.append(self.mungeButton(Image(self.website.nextIMG, border=0, alt='Next'), self.nextpage))
		s.append("<BR>\n")
		s.append(self.mungeButton(Image(self.website.sitemapIMG, border=0, alt='SiteMap'), self.website.sitemap_pg))
		s.append(self.mungeButton(Image(self.website.navhelpIMG, border=0, alt='Nav Help Page'), self.website.navhelp_pg))
		s.append(self.mungeButton(Image(self.website.searchIMG, border=0, alt='Search'), self.website.search_pg))

		return string.join(s, '')

	def footer(self):
		txt = Small("")	
		txt.append(BR())
		txt.append(Href("/Website/Philosophy.html", '"More matter, with less art." - Gertrude, Hamlet.'))
		txt.append(BR())
		txt.append('Copyright ')
		txt.append(RawText('&copy; 1997'))
		txt.append(MailTo(self.email, self.author))
		txt.append(' & ')
		txt.append(Href(self.website.homeURL, self.sitename))
		txt.append('. All Rights Reserved.')
		txt.append(BR())
		txt.append('Generated: %s' % time.ctime(time.time()))

		return ZenDocument.footer(self) + str(Paragraph( txt, align='CENTER' ))

class ZSSSiteMap(AbsSiteMap, ZSSDocument):
	""" Glues AbsSiteMap to ZSSDocument. """
	def read(self, input):
		AbsSiteMap.read(self, input)
		self.title = "ZenWeb SiteMap"

class ZSSRawDocument(AbsRawDocument, ZSSDocument):
	""" Glues AbsRawDocument to ZSSDocument. """
	None


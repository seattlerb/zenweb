#!/bin/env python

# ZSSWebsite.py
# COPYRIGHT (C) 1997-2001 Ryan Davis, Zen Spider Software
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
#
# These are the definitions that are used for www.zenspider.com
#
# Feel free to modify them to suit your site.

from HTMLgen import Image, Strong, Small, BR, Href, RawText, MailTo, Paragraph
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
		self.sitename		= 'Zen Spider Software'

	def nav_bar(self):
		"""Generate hyperlinked navigation buttons.

		If a self.*URL attribute is null that corresponding button is
		replaced with a blank gif to properly space the remaining
		buttons.
		"""
		
		s = []

		sep = " / "
		p=self.website.sitemap_pg
		s.append(str(Href(p.url, Strong("SiteMap"))))
		s.append(" | ")
		p=self.website.search_pg
		s.append(str(Href(p.url, Strong("Search"))))
		s.append(" || ")

		parent_path = [self]
		current = self
		while current.parent != None:
			current = current.parent
			parent_path.append(current)

		while len(parent_path) > 0:
			u=parent_path.pop()
			if len(parent_path) > 0:
				s.append(str(Href(u.url, u.title)))
				s.append(sep)
			else:
				s.append(u.title)

		return str(Paragraph(RawText(string.join(s, ''))))

	def footer(self):
		txt = Small("")	
		txt.append(BR())
		txt.append(Href("/Website/Philosophy.html", '"More matter, with less art." - Gertrude, Hamlet.'))
		txt.append(BR())
		txt.append('Copyright ')
		txt.append(RawText('&copy; 1997-2000'))
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


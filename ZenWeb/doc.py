#! /bin/env python

""" 
	Automatic Python Documentation in HTML (Version 0.6)

	This tool will parse all files in a given directory and build an
	internal object-structure closely resembling the code structure
	found in the files.

	Using this internal representation, the obejcts are then called
	to produce a readable output -- currently only HTML is supported.

	This module should probably make use of the standard module
	parser, I but didn't have the time back when I originally wrote
	this, to learn all about Pythons grammar and ast-trees. The
	regexp's I used work nice for most situations, though dynamically
	defined code (like code in if...else...-clauses) is not parsed.

	The doc-strings are processed by the doc_string-class and may
	contain special character sequences to enhance the output. Look
	at the as_HTML-method of that class to find out more about
	it's features.

	Caveats:
	- it will only work for doc-strings enclosed in triple double-quotes
	  that appear balanced in the source code (use \"\"\" if you have to
	  include single occurences)
	- since the doc-strings are written more or less directly into
	  the HTML-file you have to be careful about using <, > and &
	  in them, since these could lead to unwanted results, e.g.
	  like in 'if a<c then: print a>b'; writing 'if a < c then: print a > b'
	  causes no problem; _note:_ this is a feature so you can use
	  normal HTML-tags in your doc-strings; use the #-trick explained
	  in the doc_string-class instead !
	- code could be made faster by using string.join and %s... oh well.
	- doc string highlighting isn't done nicely (but works fine for my code :-)
	- tuples in function/method declarations can get this little tool
	  pretty confused...

	Notes:
	- you might want to take a look at gendoc and HTMLgen for doing
	  a more elaborate job (see: www.python.org for more infos)
	- this script executes a lot slower with Python 1.5a2 than with
	  Python 1.4; don't ask me why...

	History:
	- 0.5: minor fixes to the regexps (thanks to Tim Peters)
	- 0.6: fixed a buglet in rx_bodyindent[2] that sneaked
		   in from 0.4 to 0.5 (thanks to Dinu Gherman) and
		   added a few more /human/ formats :-)
	
	
-----------------------------------------------------------------------------
(c) Copyright by Marc-Andre Lemburg, 1997 (mailto:lemburg@uni-duesseldorf.de)

	Permission to use, copy, modify, and distribute this software and its
	documentation for any purpose and without fee is hereby granted,
	provided that the above copyright notice appear in all copies and that
	both that copyright notice and this permission notice appear in
	supporting documentation.

	THE AUTHOR MARC-ANDRE LEMBURG DISCLAIMS ALL WARRANTIES WITH REGARD TO
	THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
	FITNESS, IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL,
	INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
	FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
	NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
	WITH THE USE OR PERFORMANCE OF THIS SOFTWARE !


	RCS: $Id: //depot/main/src/ZenWeb/ZenWeb/doc.py#1 $
"""

__version__	 = '0.6'

import sys
import os
import regex
import string
import regsub
import time

#reg. expressions used
rx_class = regex.compile('\( *\)class +\([^:(]+\)\((\([^)]*\))\)? *:')
rx_function = regex.compile('\( *\)def +\([^(]+\)(\(\([^()]\|([^)]*)\)*\)) *:')
rx_method = rx_function
rx_bodyindent = regex.compile('^\( *\)[^ \n]')
rx_bodyindent_2 = regex.compile('\( *\)[^ \n]')
#cache some common parts regexps
rx_parts = {}
for indent in range(0,17,4):
	si = indent * ' '
	rs = '^'+si+'def \|^'+si+'class \|^'+si+'\"\"\"\|^'+ \
		 si+'import \|^'+si+'from \|^'+si+'[^ \n]'
	rx = regex.compile(rs)
	rx_parts[indent] = rx

# used tabsize
tabsize = 8

# some gobal options
hrefprefix = '' # put infront of all external HTML-links... helps when
				# putting the pages onto some website.
# Errors
ParseError = 'ParseError'

# some tools

def parts(text,indent):

	""" return a list of tuples (from, to, type) delimiting different
		parts in text; the whole text has to be indented by indent spaces
		* text must be TAB-free
		* type can be: def, class, \"\"\", import, from, <none of these>
		* this will only find statically defined objects -- using
		  if's to do conditional defining breaks this method
	"""

	# get parts regexp -- from cache if possible
	try:
		rx = rx_parts[indent]
	except:
		si = indent * ' '
		rs = '^'+si+'def \|^'+si+'class \|^'+si+'\"\"\"\|^'+ \
				 si+'import \|^'+si+'from \|^'+si+'[^ \n]'
		rx = regex.compile(rs)
		rx_parts[indent] = rx
	l = [[0,0,'']]
	start = 0
	while 1:
		t = rx.search(text,start)
		if t != -1:
			type = rx.group(0)[indent:]
			if type[-1] == ' ': type = type[:-1]
			l[-1][1] = t # the last part ends here ...
			l.append([t,t,type]) # ... while the new one starts here
			start = rx.regs[0][1]
		else:
			break
	l[-1][1] = len(text)
	l = map(tuple,l)
	return l
	
def calc_bodyindent(text,start=0):

	""" calculate the bodyindent of the code starting at text[start:] """
	
	# this one works in most cases
	rx = rx_bodyindent
	if rx.search(text,start) != -1:
		a,b = rx.regs[1]
		return b-a
	else:
		# maybe there are no new lines left (e.g. at the end of a file)
		rx = rx_bodyindent_2
		if rx.search(text,start) != -1:
			a,b = rx.regs[1]
			return b-a
		else:
			# didn't think of this one... 
			print 'bodyindent failed for:\n--|'+text[start:]+'|-- why?'
			return 0

def subst(find,sub,text):

	""" substitute sub for every occurence of find in text """

	l = string.splitfields(text,find)
	return string.joinfields(l,sub)

def fix_linebreaks(text):
	
	""" want to have Unix-style newlines everywhere (that is, no \r!) """

	text = subst('\r\n','\n',text)
	return subst('\r','\n',text)

def escape_long_strings(text):

	""" escape long string newlines so they don't disturb part-breaking
		* this only works, iff the long strings occur balanced everywhere
	"""

	l = string.splitfields(text,'\"\"\"')
	for i in range(1,len(l),2):
		l[i] = subst('\n','\r',l[i])
	return string.joinfields(l,'\"\"\"')

def unescape_long_strings(text):

	""" inverse of the above function """

	l = string.splitfields(text,'\"\"\"')
	for i in range(1,len(l),2):
		l[i] = subst('\r','\n',l[i])
	return string.joinfields(l,'\"\"\"')

def extract_doc_string(text):

	""" extract and unescape doc-string from long-string-part """

	l = string.splitfields(text,'\"\"\"')
	s = subst('\r','\n',l[1])
	return s

def fullname(doc):

	""" return the full name of a doc-class, that is the names of its
		owners and itself, concatenated with dots 
		-- the usual Python-fashion of naming things
	"""

	t = doc.name
	while doc.owner != None:
		doc = doc.owner
		t = doc.name + '.' + t
	return t

# the doc-classes

class doc_string:

	def __init__(self,text,owner=None):

		""" interpret text as a doc-string; instance-variables:
			* text	  - original doc-string
			* owner	  - owner-class of this object: this object is a member
						of its super-object, e.g. a function
		"""
		self.text = text

	def __str__(self):

		return self.text

	def as_HTML(self):

		""" return a HTML-Version of the doc-string; tries to interpret certain
			human formatting styles in HTML:
			* single leading *,+,- become list markers
			* lines of - or = turn into horizontal rules
			* empty lines serve as paragraph separators
			* the first paragraph is written in italics

			* emphasized writing of single words:
				 ' *bold* ' turns out bold
				 ' _underlined_ ' turns out underlined
				 ' /italics/ ' comes out in italics

			* lines starting or ending with a # are written monospaced
			  and the '#' signaling this is deleted; example:

			  # def unescape_long_strings(text):
			  #	  l = string.splitfields(text,'\"\"\"')
			  #	  for i in range(1,len(l),2):
			  #		  l[i] = subst('\r','\n',l[i])
			  #	  return string.joinfields(l,'\"\"\"')

			  The '#' indicates the start-of-line, that is only spaces
			  after the comment mark turn up as spaces ! Or use:

			  def unescape_long_strings(text):					#
				l = string.splitfields(text,'\"\"\"')			#
				for i in range(1,len(l),2):						#
					l[i] = subst('\r','\n',l[i])				#
				return string.joinfields(l,'\"\"\"')			#

			  In this case all spaces on the left are layouted as such.
			  The lines are concatinated into one XMP-field,
			  so HTML-tags won't work in here -- e.g.

			  # <BODY>
			  #	 <B> Works ! </B>
			  # </BODY>

			  gives you an easy-to-use alternative to using the
			  XMP-tag directly.

			* If you plan to put verbatim HTML-code inline then you can
			  use this syntax \<I>This doesn't come out in italics\</I>, i.e.
			  put a backslash in front of the tag. (The tag must not
			  contain embedded '>' characters.)

			* Note: 'lines' in this context refer to everything between
			  two newlines

			* The formatting demonstrated here won't show up in the
			  HTML-output of this doc-string, so you'll have to look
			  at the source code to find out how it works...
		"""

		t = string.strip(self.text) + '\n'
		# HTML Entities:
		t = regsub.gsub('&', '&amp;', t)
		# bullets:
		t = regsub.gsub('^ *[\*+-] ','<LI>',t)
		# rules
		t = regsub.gsub('^ *[-=]+\n','<HR>\n',t)
		# empty lines == paragraphs
		t = regsub.gsub('^[\t\ ]*\n','\n',t)
		# guess first paragraph
		t = regsub.gsub('\`\([^<]*\)','\\1\n',t)
		# monospaced stuff, e.g. code
		t = regsub.gsub('^ *#\(.*\)\n','<XMP>\\1</XMP>\n',t)
		t = regsub.gsub('^\(.*\)#\n','<XMP>\\1</XMP>\n',t)
		t = regsub.gsub('</XMP>\n<XMP>','\n',t)
		# inline HTML
		t = regsub.gsub('\\\\<\(/*[A-Za-z][^>]*\)>','<TT>&lt;\\1&gt;</TT>',t)
		# emphasizing
		t = regsub.gsub(' \*\([^ \*]+\)\* ',' <B>\\1</B> ',t)
		t = regsub.gsub(' _\([^ _]+\)_ ',' <U>\\1</U> ',t)
		t = regsub.gsub(' /\([^ /]+\)/ ',' <I>\\1</I> ',t)

		# RWD t = '<DD>%s</DD>' % t

		return t

class doc_class:

	def __init__(self,text,sx,sy,owner=None):
	
		""" parse the text part [sx:sy] for a class definition and all its
			members; instance-variables:
			* text	  - original code
			* slice	  - the part of text where the class def is supposed to be
						found
			* owner	  - owner-class of this object: this object is a member
						of its super-object, e.g. a module
			* indent  - indent of this def
			* name	  - the class name
			* fullname - the full name of this class
			* baseclasses - list of names of baseclasses
			* doc	  - doc-string as doc_string-object
			* methods - list of methods as doc_method-objects
			* classes - list of classes as doc_class-objects
			* bodyindent - indent of the definitions body
			* parts	  - definition body, broken into parts
		"""
		self.text = text
		self.slice = (sx,sy)
		self.owner = owner
		rx = rx_class
		start = rx.match(text,sx)
		if start < 0:
			# we've got a problem here
			print "-- can't find the class definition in:"
			print text[sx:sy]
			raise ParseError,"couldn't parse class definition"
		start = start + sx
		self.indent = len(rx.group(1))
		self.name = rx.group(2)
		if rx.group(3) != None:
			self.baseclasses = string.splitfields(rx.group(4),',')
		else:
			self.baseclasses = []
		self.doc = doc_string('No Documentation.',self)
		self.methods = []
		self.classes = []
		self.fullname = fullname(self)
		# calc body-indent
		self.bodyindent = calc_bodyindent(text,start)
		# break into parts
		self.parts = parts(text[start:sy],self.bodyindent)
		try:
			for x,y,type in self.parts:
				if	type == 'def': 
					# got a method
					self.methods.append(doc_method(text,start+x,start+y,self))
				elif type == 'class':
					# got a class
					self.classes.append(doc_class(text,start+x,start+y,self))
				elif type == '#':
					# got a comment
					pass
				elif type == '\"\"\"':
					# got a doc-string
					self.doc = doc_string(extract_doc_string(text[start+x:start+y]),self)
				else:
					# something else
					pass
		except ParseError,reason:
			print '-- ParseError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this class (%s)'%self.fullname
		except regex.error,reason:
			print '-- RegexError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this class (%s)'%self.fullname

	def as_HTML(self):

		""" give a HTML-version of the class and its members """

		output = '<DT><BR><CODE>class <A NAME="'+self.fullname+'"><STRONG>'+self.name+'</STRONG></A> ('+ \
				 string.joinfields(self.baseclasses,',')+')</CODE></DT>'+\
				 '\n<DD><DL>'+ self.doc.as_HTML()

		if self.methods != []:
			output = output + '<DT><BR>Methods:</DT>\n<DD><DL>'
			for m in self.methods:
				output = output + "\n" + m.as_HTML()
			output = output + '\n</DL></DD>'
		if self.classes != []:
			output = output + '<DT><BR>Classes:</DT>\n<DD><DL>'
			for m in self.classes:
				output = output + "\n" + m.as_HTML()
			output = output + '\n</DL></DD>'
		return output + '\n</DL></DD>'

class doc_method:

	def __init__(self,text,sx,sy,owner=None):
	
		""" parse the text part [sx:sy] for a method definition and all its
			members; instance-variables:
			* text	  - original code
			* slice	  - the part of text where the class def is supposed to be
						found
			* owner	  - owner-class of this object: this object is a member
						of its super-object, e.g. a module
			* indent  - indent of this def
			* name	  - the class name
			* fullname - the full name of this class
			* parameters - list of parameters needed for this method (without self)
			* doc	  - doc-string as doc_string-object
			* functions - list of functions as doc_function-objects
			* classes - list of classes as doc_class-objects
			* bodyindent - indent of the definitions body
			* parts	  - definition body, broken into parts
		"""
		self.text = text
		self.slice = (sx,sy)
		self.owner = owner
		rx = rx_method
		start = rx.match(text,sx)
		if start < 0:
			# we've got a problem here
			print "-- can't find the method definition in:"
			print text[sx:sy]
			raise ParseError,"couldn't parse method definition"
		start = start + sx
		self.indent = len(rx.group(1))
		self.name = rx.group(2)
		self.parameters = string.splitfields(rx.group(3),',')[1:]
		self.doc = doc_string('No Documentation.',self)
		self.functions = [] # don't think these are really needed...
		self.classes = []	# -"-
		self.fullname = fullname(self)
		# calc body-indent
		self.bodyindent = calc_bodyindent(text,start)
		# break into parts
		self.parts = parts(text[start:sy],self.bodyindent)
		try:
			for x,y,type in self.parts:
				if	type == 'def': 
					# got a function
					# RWD self.functions.append(doc_function(text,start+x,start+y,self))
					doc_function(text,start+x,start+y,self)
				elif type == 'class':
					# got a class
					# RWD self.classes.append(doc_class(text,start+x,start+y,self))
					doc_class(text,start+x,start+y,self)
				elif type == '#':
					# got a comment
					pass
				elif type == '\"\"\"':
					# got a doc-string
					self.doc = doc_string(extract_doc_string(text[start+x:start+y]),self)
				else:
					# something else
					pass
		except ParseError,reason:
			print '-- ParseError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this method (%s)'%self.fullname
		except regex.error,reason:
			print '-- RegexError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this method (%s)'%self.fullname

	def as_HTML(self):

		""" give a HTML-version of the method and its members """

		output = '<DT><BR><CODE>def <A NAME="'+self.fullname+'"><STRONG>'+self.name+'</STRONG></A> ('+\
				 string.joinfields(self.parameters,',')+')</CODE></DT>'+\
				 '<DD><DL>' + self.doc.as_HTML()

		if self.classes != []:
			output = output + '<DT><BR>Classes:</DT>\n<DD><DL>'
			for m in self.classes:
				output = output + "\n" + m.as_HTML()
			output = output + '</DL></DD>'
		if self.functions != []:
			output = output + '<DT><BR>Functions:</DT>\n<DD><DL>'
			for m in self.functions:
				output = output + "\n" + m.as_HTML()
			output = output + '\n</DL></DD>'
		return output + '\n</DL></DD>'

class doc_function:

	def __init__(self,text,sx,sy,owner=None):
	
		""" parse the text part [sx:sy] for a method definition and all its
			members; instance-variables:
			* text	  - original code
			* slice	  - the part of text where the class def is supposed to be
						found
			* owner	  - owner-class of this object: this object is a member
						of its super-object, e.g. a module
			* indent  - indent of this def
			* name	  - the class name
			* fullname - the full name of this class
			* parameters - list of parameters needed for this function
			* doc	  - doc-string as doc_string-object
			* functions - list of functions as doc_function-objects
			* classes - list of classes as doc_class-objects
			* bodyindent - indent of the definitions body
			* parts	  - definition body, broken into parts
		"""
		self.text = text
		self.slice = (sx,sy)
		self.owner = owner
		rx = rx_function
		start = rx.match(text[sx:sy])
		if start < 0:
			# we've got a problem here
			print "-- can't find the function definition in:"
			print text[sx:sy]
			raise ParseError,"couldn't parse function definition"
		start = start + sx
		self.indent = len(rx.group(1))
		self.name = rx.group(2)
		self.parameters = string.splitfields(rx.group(3),',')
		self.doc = doc_string('No Documentation.',self)
		self.functions = []
		self.classes = []
		self.fullname = fullname(self)
		# calc body-indent
		self.bodyindent = calc_bodyindent(text,start)
		# break into parts
		self.parts = parts(text[start:sy],self.bodyindent)
		try:
			for x,y,type in self.parts:
				if	type == 'def': 
					# got a function
					# RWD self.functions.append(doc_function(text,start+x,start+y,self))
					doc_function(text,start+x,start+y,self)
				elif type == 'class':
					# got a class
					# RWD self.classes.append(doc_class(text,start+x,start+y,self))
					doc_class(text,start+x,start+y,self)
				elif type == '#':
					# got a comment
					pass
				elif type == '\"\"\"':
					# got a doc-string
					self.doc = doc_string(extract_doc_string(text[start+x:start+y]),self)
				else:
					# something else
					pass
		except ParseError,reason:
			print '-- ParseError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this function (%s)'%self.fullname
		except regex.error,reason:
			print '-- RegexError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this function (%s)'%self.fullname

	def as_HTML(self):

		""" give a HTML-version of the function and its members """

		output = '<DT><BR><CODE>def <A NAME="'+self.fullname+'"><STRONG>'+self.name+'</STRONG></A> ('+\
				 string.joinfields(self.parameters,',')+') </CODE></DT>'+\
				 '\n<DD><DL>' + self.doc.as_HTML()

		if self.classes != []:
			output = output + '<DT><BR>Classes:</DT>\n<DD><DL>'
			for m in self.classes:
				output = output + "\n" + m.as_HTML()
			output = output + '\n</DL></DD>'
		if self.functions != []:
			output = output + '<DT><BR>Functions:</DT>\n<DD><DL>'
			for m in self.functions:
				output = output + "\n" + m.as_HTML()
			output = output + '\n</DL></DD>'
		return output + '\n</DL></DD>'

class doc_module:

	def __init__(self,file,owner=None):

		""" parse the source code in file as Python module
			* owner	  - owner-class of this object: this object is a member
						of its super-object, e.g. a project
			* name	  - the module name
			* doc	  - doc-string as doc_string-object
			* functions - list of funtions as doc_function-objects
			* methods - list of methods as doc_method-objects
			* classes - list of classes as doc_class-objects
			* parts	  - definition body, broken into parts
		"""
		# read file, expand tabs, fix line breaks and long strings
		self.file = file
		self.text = open(self.file).read()
		self.text = string.expandtabs(self.text,tabsize)
		self.text = fix_linebreaks(self.text)
		self.text = escape_long_strings(self.text)
		# I need a linebreak at the file end to make things easier:
		if self.text[-1] != '\n':
			self.text = self.text + '\n'
		self.name = os.path.split(file)[1][:-3] # strip path and .py
		self.owner = owner
		# break into parts
		self.parts = parts(self.text,0)
		# parse
		self.functions = []
		self.classes = []
		self.doc = doc_string('No Documentation.',self)
		try:
			for x,y,type in self.parts:
				if	type == 'def': 
					# got a function
					self.functions.append(doc_function(self.text,x,y,self))
				elif type == 'class':
					# got a class
					self.classes.append(doc_class(self.text,x,y,self))
				elif type == '#':
					# got a comment
					pass
				elif type == '\"\"\"':
					# got a doc-string
					self.doc = doc_string(extract_doc_string(self.text[x:y]),self)
				else:
					# something else
					pass
		except ParseError,reason:
			print '-- ParseError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this module (%s)'%file
		except regex.error,reason:
			print '-- RegexError:',reason
			print '-- was looking at:\n',text[start+x:start+y]
			print '-- Skipping the rest of this module (%s)'%file

	def as_HTML(self):

		""" give a HTML-version of the module and its members """

		output = '<H1>Module: <A NAME="'+self.name+'">'+self.name+'</A></H1>'+\
			'<DL>\n' + self.doc.as_HTML()

		if self.classes != []:
			output = output + '<DT><BR>Classes:</DT>\n<DD><DL>'
			for m in self.classes:
				output = output + "\n" + m.as_HTML()
			output = output + '</DL></DD>\n'
		if self.functions != []:
			output = output + '<DT><BR>Functions:</DT>\n<DD><DL>'
			for m in self.functions:
				output = output + "\n" + m.as_HTML()
			output = output + '</DL></DD>\n'
		return output + '</DL>'


class doc_project:

	def __init__(self,path,name='test'):

		""" find all Python-files in path and parse them via doc_module
			* name	  - project name
			* path	  - pathname
			* files	  - filenames found
			* modules - list of modules as doc_module-objects
		"""
		self.name = name
		self.path = path
		self.files = filter(lambda f: f[-3:]=='.py', os.listdir(path))
		self.files.sort()
		self.modules = []
		for f in self.files:
			print ' scanning',f
			self.modules.append(doc_module(os.path.join(path,f)))

	def make_HTML(self):

		""" create a HTML-version of the project and its members using
			FRAMES and three files: the frameset-file, the module index and the
			content file
		"""

		print 'making files...'

		for m in self.modules:
			# set filenames
			self.content = m.name+'.html'
	
			# open files
			content = open(self.content,'w')
	
			# make content-file
			print '', self.content
			output = """<HTML>\n\t<HEAD>\n\t\t<TITLE>%s</TITLE>\n\t</HEAD>\n\t<BODY BGCOLOR=#FFFFFF>\n""" \
						% (m.name)
			output = output + m.as_HTML()
			output = output + '	</BODY>\n</HTML>'
			content.write(output)
			content.close()

# simple interface:

def main():

	global hrefprefix

	print 'Doc-Tool V'+__version__+' (c) M.A.Lemburg,1997; mailto:lemburg@uni-duesseldorf.de'
	print
	if len(sys.argv) < 3:
		print 'Syntax:',sys.argv[0],'project-name project-dir [HREF-prefix]'
		print
		print 'The tool will create HTML-files with prefix <project-name> containing'
		print 'the doc-strings of the found Python-files in a structured form.'
		print 'The links in these files will be prepended with HREF-prefix, if'
		print 'given, to simplify the upload to a website.'
		print
		print sys.argv
		print
		print 'Enjoy !'
		sys.exit()
	print 'Working on project:',sys.argv[1],'residing in',sys.argv[2]
	print
	print 'Creating files...'
	if len(sys.argv) >= 4:
		hrefprefix = sys.argv[3]
	else:
		hrefprefix = ''
	p = doc_project(sys.argv[2],sys.argv[1])
	p.make_HTML()
	print 'Done. Point your browser at',hrefprefix+sys.argv[1]+'.html'

if __name__ == '__main__':
	main()

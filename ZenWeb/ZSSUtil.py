from HTMLgen import mpath
import os
import regex

######################################################################
#
# Filename	: ZSSUtil.py
# Author	: Ryan Davis (RWD) <mailto:zss@POBoxes.com>
#
# COPYRIGHT (C) 1999 Zen Spider Software & Ryan Davis
#
# Permission to use, copy, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice and this permission notice 
# appear in all copies. You may not modify this software or it's
# documentation without explicit permission from the author.
#
# The author disclaims all warranties with regard to this
# software, explicit or implied, regarding the use or performance
# of this software.
#
# Revisions	::
# 1.0.0    MM/DD/YY Birthday.
#
######################################################################

""" ZSSUtil is a class library providing miscellaneous services and utilities.
	That are otherwise missing or more basic in the Python class libraries.
"""

def fileIsNewerThan(a, b):
	""" Returns true if both "a" and "b" exist and "a" has been modified more recently than "b". """
	from stat import ST_MTIME
	import os
	return (os.path.exists(a) \
		and os.path.exists(b) \
		and os.stat(a)[ST_MTIME] >= os.stat(b)[ST_MTIME]) \
		or (os.path.exists(a) and not os.path.exists(b))

def myopen(filename, mode = 'r', bufsize = -1):
	""" Provides a wrapper for open that handles errors better """
	path = mpath(filename)
	try:
		return open( path, mode, bufsize )
	except IOError, io:
		print "Couldn't open %s: %s (pwd = %s)\n" % (path, io, os.getcwd())
		raise IOError, io

def makedirs(path, isFile=None):
	""" Equivalent to 'mkdir -p path'.
		Take a path, real or not, and a boolean specifying if the last part
		of the path is a file or not. If the path already exists, then return.
		Split the path into head & tail and recurse on head (using default isFile).
		Once we return from the recursion, the head path now exists.
		If isFile is not true, make the directory specified by path
	"""

	if os.path.isfile(path) or os.path.isdir(path):
		return
	head, tail = os.path.split(path)
	makedirs(head)
	if not isFile and not os.path.exists(path):
		os.mkdir(path, 0777)

def createList(data=[]):
	""" Scan through a list of strings converting to a list of (lists and strings).
		If a string starts with a tab, then it (and following items) are converted
		into a sublist. MORE LATER
	"""
	min = -1
	max = -1
	re_tabs = regex.compile('^\t\(\t*.*\)')
	
	i = 0
	while (i < len(data)):
		if (min == -1):						# looking for initial match
			if (re_tabs.search(data[i]) > -1):
				data[i] = re_tabs.group(1)	# replace w/ 1 less tab
				min = i
		else:								# found match, looking for mismatch
			if (not re_tabs.search(data[i]) > -1 or i == len(data)):
				max = i
				newdata = createList(data[min:max])
				data[min:max] = [ newdata ]
				i = min
				min = -1
				max = -1
			else:
				data[i] = re_tabs.group(1)	# replace w/ 1 less tab
		i = i + 1
	if (i >= len(data)-1 and min != -1):
		max = i
		newdata = createList(data[min:max])
		data[min:max] = [ newdata ]
	return data

######################################################################
# Main

if __name__ == '__main__':

	path = ":killme:I:don't:exist:"

	print "Testing myopen. You should see an error message."
	try:
		myopen(path + "someFile")
	except IOError:
		None

	print "Testing makedirs."
	makedirs(path)
	makedirs(path)

	print "Testing createList."
	list = [ "a", "b", "\tc", "\t\td", "\te", "f" ]
	print "%s becomes %s" % (list, createList(list[:]))
	
	print "Done testing..."

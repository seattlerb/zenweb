ZenWeb
    http://www.zenspider.com/ZSS/Products/ZenWeb/
    support@zenspider.com

DESCRIPTION:
  
ZenWeb is a set of classes/tools for organizing and formating a
website. It is website oriented rather than webpage oriented, unlike
most rendering tools. It is content oriented, rather than style
oriented, unlike most rendering tools. It provides a plugin system of
renderers and filters to provide a very flexible, and powerful system.

Documentation is available in the docs directory, and can be generated
into html (in docshtml) simply by running make. See QuickStart and
YourOwnWebsite for setup and starting to build a website.
  
(EXPERIMENTAL) If you are running apache, you might try 'make apache'
which will run a private version of apache that points to the
generated documenation. Point your browser to port 8080 of localhost
or whatever machine you are running on.

FEATURES:
  
+ SiteMap oriented for a comprehensive website.
+ Generic architecture w/ a set of plugins to extend any page or directory.
+ Incremental page builds for very fast generation.
+ Simple text-to-html markup makes creating large websites easy.
+ ZenTest 1.0 compliant. http://sf.net/projects/zentest/
+ Much much more... I should probably add that here, huh?

REQUIREMENTS:

+ Ruby - 1.6.5-7 and 1.7.2 have been tested.
+ Test::Unit testing framework via RAA on http://www.ruby-lang.org/.

INSTALL:

+ make test && sudo make install

LICENSE:

(The MIT License)

Copyright (c) 2001-2002 Ryan Davis, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

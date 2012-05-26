= ZenWeb

home :: https://github.com/seattlerb/zenweb
bugs :: https://github.com/seattlerb/zenweb/issues
rdoc :: http://docs.seattlerb.org/zenweb

== DESCRIPTION:
  
Zenweb is a set of classes/tools for organizing and formating a
website. It is website oriented rather than webpage oriented, unlike
most rendering tools. It is content oriented, rather than style
oriented, unlike most rendering tools. It uses a rubygems plugin
system to provide a very flexible, and powerful system.

Zenweb 3 was inspired by jekyll. The filesystem layout is similar to
jekyll's layout, but zenweb isn't focused on blogs. It can do any sort
of website just fine.

Zenweb uses rake to handle dependencies. As a result, scanning a
website and regenerating incrementally is not just possible, it is
blazingly fast.

== FEATURES:
  
* Uses rake to do intelligent incremental builds.
* Uses rubygems to provide a flexible plugin system.
* Provides plugins for less, markdown, and erb out of the box.
* Uses a hierarchical config/variable system making pages cleaner.
* Has syntax highlighting via coderay.
* Blazingly fast.
* Stupidly flexible.
* TODO: provide more templates via gem extensions.
* TODO: provide more migrators via gem extensions.

== REQUIREMENTS:

* rubygems
* rake
* kramdown
* coderay
* rb-fsevent

== INSTALL:

* gem install zenweb

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, Seattle.rb

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

#!/usr/local/bin/ruby -w

def usage
  puts "#{$0} filepath [title [subtitle]]"
  exit 1
end

path     = ARGV.shift || usage()
title    = ARGV.shift || 'Title'
subtitle = ARGV.shift || 'Subtitle'

filename = File.basename(path)

puts "Creating #{filename}"

file = File.new(path, "w")

if filename == 'metadata.txt' then
  file.puts "'renderers' = [ 'StandardRenderer' ]"
elsif filename == 'Makefile' then
  file.puts "# use this to override"
  file.puts "RUBYPATH="
  file.puts "DEBUG="
  file.puts "ZENWEB=/usr/local/bin/zenweb"
  file.puts "INSTALLDIR=/usr/local/www"
  file.puts ""
  file.puts "all: html"
  file.puts ""
  file.puts "html:"
  file.puts "	RUBYPATH=$(RUBYPATH) ruby $(DEBUG) $(ZENWEB) data"
  file.puts ""
  file.puts "realclean: clean"
  file.puts "	-rm -rf html"
  file.puts ""
  file.puts "clean:"
  file.puts "	rm -rf httpd.conf httpd.pid error.log access.log"
  file.puts "	-find . -name \*~ -exec rm {} \;"
  file.puts "	-find data -name \*.html -print0 | xargs -0 rm -f"
  file.puts ""
  file.puts "apache: all"
  file.puts %q%	grep -v CustomLog $$(httpd -V | grep SERVER_CONFIG_FILE | cut -f 2 -d= | cut -f 2 -d\") > httpd.conf; httpd -X -d $$PWD/html -f $$PWD/httpd.conf  -c "PidFile $$PWD/httpd.pid" -c "Port 8080" -c "ErrorLog $$PWD/error.log" -c "TransferLog $$PWD/access.log" -c "DocumentRoot $$PWD/html"%
  file.puts ""
  file.puts "copy:"
  file.puts "	rsync -r html/ $(INSTALLDIR)"
  file.puts ""
  file.puts ".PHONY: all html clean copy"
else
  file.puts "# 'title' = '#{title}'"
  file.puts "# 'subtitle' = '#{subtitle}'"
  file.puts "# 'keywords' = 'Keywords used by search engines.'"
  file.puts "# 'description' = 'Basic desc for search engines.'"

  if filename == 'SiteMap' then
    file.puts "# 'renderers' = [ 'SitemapRenderer', 'StandardRenderer' ]"
    file.puts ""
    file.puts "/index.html"
    file.puts "/SiteMap.html"
  else
    file.puts ""
    file.puts "** Section Header"
    file.puts ""
    file.puts "TO" + "DO: write this page" # to avoid my source TAG scanner
  end
end

file.close

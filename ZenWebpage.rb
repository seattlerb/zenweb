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

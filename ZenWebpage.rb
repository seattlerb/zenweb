#!/usr/local/bin/ruby -w

def usage
  puts "#{$0} filepath [title [subtitle]]"
  exit 1
end

path     = ARGV.shift || usage()
title    = ARGV.shift || 'Title'
subtitle = ARGV.shift || 'Subtitle'

file = File.new(path, "w")
file.puts "# 'title' = '#{title}'"
file.puts "# 'subtitle' = '#{subtitle}'"
file.puts "# 'keywords' = 'Keywords used by search engines.'"
file.puts "# 'description' = 'Basic desc for search engines.'"
file.puts ""
file.puts "** Section Header"
file.puts ""
file.puts "TO" + "DO: write this page" # to avoid my source TAG scanner
file.close

#!/usr/local/bin/ruby -w

path     = ARGV.shift || raise(ArgumentError, "Need a file.")
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
file.puts "TODO: write this page"
file.close

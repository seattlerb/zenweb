#!/usr/local/bin/ruby -w

def usage
  puts "#{$0} dir"
  exit 1
end

def error(msg)
  $stderr.puts(msg)
  exit 1
end

base = File.expand_path(File.dirname($0))
path = ARGV.shift || usage()

cmd = "#{base}/ZenWebpage.rb"
unless test ?f, cmd then
  puts "Can't find ZenWebpage.rb in #{base}, falling back to PATH"
  cmd = "ZenWebpage.rb"
end

puts "Using #{cmd} to create files"
puts "Creating directory #{File.basename(path)}"

Dir.mkdir(path)
Dir.chdir(path)

system("#{base}/ZenWebpage.rb Makefile") or error("Failed: #{$?}")

Dir.mkdir("data")
Dir.chdir("data")

system("#{base}/ZenWebpage.rb SiteMap SiteMap") or error("Failed: #{$?}")
system("#{base}/ZenWebpage.rb metadata.txt") or error("Failed: #{$?}")
system("#{base}/ZenWebpage.rb index Welcome") or error("Failed: #{$?}")

Dir.chdir("..")

system("make") or error("Failed: #{$?}")

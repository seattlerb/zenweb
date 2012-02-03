require 'zenweb'

task :default => :generate

def website
  $website = Zenweb::Site.new
  $website.scan
  $website.wire
  $website
rescue RuntimeError => e
  p e
  puts e.backtrace.join "\n"
  raise e
end

website if ENV['ALL']

desc "Generate the website."
task :generate do
  site = website

  site.generate

  found = Dir[".site/**/*"].select { |f| File.file? f }.sort
  known = site.pages.values.map { |p| p.url_path }.sort
  rm found - known
end

desc "Push changes to the site. (you need to define this)"
task :push

desc "Publish your website: clean, generate, push."
task :publish => [:clean, :generate, :push]

desc "Remove junk files."
task :clean do
  rm_rf Dir["**/*~"]
end

desc "Remove generated .site directory."
task :realclean => :clean do
  rm_rf ".site"
end

desc "Run a webserver and build on the fly."
task :run do
  require 'webrick'

  class ZenwebBuilder < WEBrick::HTTPServlet::FileHandler
    def service req, res
      url = req.path
      target_path = File.join(@root, url)

      source_file = req.path.
        gsub(/(\d\d\d\d)\/(\d\d)\/(\d\d)\//, '\1-\2-\3-').
        gsub(/(\d\d\d\d)\/(\d\d)\//, '\1-\2-')

      if File.directory? File.join(@root, url) then
        source_file += "index.html"
        target_path += "index.html"
      end

      sources = Dir[".#{source_file}*"]

      newer = sources.find { |p|
        ! File.exist?(target_path) or File.mtime(p) > File.mtime(target_path)
      }

      system "rake clean generate" if newer

      super
    end
  end

  server = WEBrick::HTTPServer.new :Port => 8000
  server.mount '/', ZenwebBuilder, ".site"

  trap 'INT' do
    server.shutdown
  end

  server.start
end

desc "Debug the generation of a file. Takes a PATH arg."
task :debug => ".site" do
  site = website

  path = ENV['PAGE'] || ENV['F'] || ENV['FILE'] || "index.html.erb"

  if path then
    page = site.pages[path]
    page.generate

    puts
    puts File.read page.url_path
  end
end

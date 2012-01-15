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

desc "Generate the website"
task :generate do
  site = website

  site.generate

  found = Dir[".site/**/*"].select { |f| File.file? f }.sort
  known = site.pages.values.map { |p| p.url_path }.sort
  rm found - known
end

desc "Push changes to the site"
task :push

desc "Update current website"
task :publish => [:clean, :generate, :push]

desc "remove generated directories"
task :clean do
  rm_rf Dir["**/*~"]
end

desc "remove generated .site directory"
task :realclean => :clean do
  rm_rf ".site"
end

task :dev do
  require 'webrick'

  class ZenwebBuilder < WEBrick::HTTPServlet::FileHandler
    def service req, res
      url = req.path
      target_path = File.join(@root, url)

      source_file = req.path.gsub(/(\d\d\d\d)\/(\d\d)\/(\d\d)\//, '\1-\2-\3-')

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

task :debug do
  site = website

  path = ENV['PAGE'] || "index.html.erb"

  if path then
    page = site.pages[path]

    page.generate

    puts
    puts File.read page.url_path
  end
end

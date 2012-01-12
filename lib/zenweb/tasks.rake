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
  website.generate
end

desc "Push changes to the site"
task :push

desc "Update current website"
task :publish => [:clean, :generate, :push]

desc "remove generated directories"
task :clean do
  rm_rf Dir["**/*~"]
end

desc "remove generated directories"
task :realclean => :clean do
  rm_rf ".site"
end

task :dev do
  require 'rb-fsevent'
  require 'webrick'

  mime_types = WEBrick::HTTPUtils::DefaultMimeTypes.dup

  server = WEBrick::HTTPServer.new(:DocumentRoot => ".site",
                                   :Port => 8000,
                                   :MimeTypes => mime_types)

  fsevent = FSEvent.new
  fsevent.watch Dir.pwd do |directories|
    directories.reject! { |d| d =~ /\.site/ }
    system "rake" unless directories.empty?
  end

  threads = []
  threads << Thread.new { server.start }
  threads << Thread.new { fsevent.run }

  trap 'INT' do
    server.shutdown
    fsevent.stop
  end

  threads.each do |t|
    t.join
  end
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

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

desc "Generate the website."
task :generate do
  site = website

  site.generate

  found = Dir[".site/**/*"].select { |f| File.file? f }.sort
  known = site.pages.values.map { |p| p.url_path }.sort
  rm found - known
end

desc "Print out possible orphans (html pages w/o parent pages)"
task :orphans do
  site = website
  puts "Possible Orphans (HTML pages w/o parents):"
  puts
  site.pages.values.reject(&:parent).sort_by(&:clean_url).each do |page|
    next unless page.url =~ /html$/
    puts page
  end
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

def new_file title, dated = false
  path = "#{title.strip.downcase.gsub(/\W+/, '-')}.html.md"

  if dated then
    today = Time.now.strftime '%Y-%m-%d'
    path = "#{today}-#{path}"
  end

  open path, 'w' do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title}\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
    post.puts "comments: true"
    post.puts "categories: "
    post.puts "---"
  end
end

desc "Begin a new dated post: rake new_post['title']"
task :new_post, :title do |t, args|
  title = args[:title] || "new-post"

  new_file title, true

  warn "Created new post: #{path}"
end

desc "Begin a new dated post: rake new_page['title']"
task :new_page, :title do |t, args|
  title = args[:title] || "new-post"

  new_file title

  warn "Created new file: #{path}"
end

desc "Run a webserver and build on the fly."
task :run do
  require 'webrick'
  require 'thread'

  class ZenwebBuilder < WEBrick::HTTPServlet::FileHandler
    @@semaphore = Mutex.new

    def service req, res

      @@site ||= @@semaphore.synchronize { website }

      url = req.path
      target_path = File.join(".site", url)

      task = Rake.application[target_path] rescue nil

      newer = task && task.needed?

      if newer then
        system "rake clean generate"
        @@site = nil
        Rake.application = Rake::Application.new
      end

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

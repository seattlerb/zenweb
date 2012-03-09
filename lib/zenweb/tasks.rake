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
    post.puts "date: #{Time.now.iso8601}"
    post.puts "comments: true"
    post.puts "categories: "
    post.puts "..."
    post.puts
  end

  path
end

desc "Begin a new dated post: rake new_post['title']"
task :new_post, :title do |t, args|
  title = args[:title] || "new-post"

  path = new_file title, true

  warn "Created new post: #{path}"
end

desc "Begin a new dated post: rake new_page['title']"
task :new_page, :title do |t, args|
  title = args[:title] || "new-post"

  path = new_file title

  warn "Created new file: #{path}"
end

desc "Run a webserver and build on the fly."
task :run do
  require 'webrick'
  require 'thread'

  # TODO: implement a watcher or something... this is annoying
  class ZenwebBuilder < WEBrick::HTTPServlet::FileHandler
    @@semaphore = Mutex.new

    def self.start_builder
      @@builder ||= Thread.new do
        loop do
          sleep 5

          system "rake -q clean generate"
        end
      end
    end

    def self.stop_builder
      @@builder.kill
    end

    def service req, res
      @@site ||= @@semaphore.synchronize { website }

      url = req.path
      target_path = File.join(".site", url)

      target_path = File.join target_path, "index.html" if
        File.directory? target_path

      task = Rake.application[target_path] rescue nil

      if task then
        puts task
      else
        warn "NOTE: No file found for #{url}"
      end

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
  # ZenwebBuilder.start_builder
  server.mount '/', ZenwebBuilder, ".site"

#  ZenwebBuilder.start_builder

  trap 'INT' do
    # ZenwebBuilder.stop_builder
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

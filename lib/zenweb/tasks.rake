require 'zenweb'

task :default => :generate

def website
  return $website if defined?($website) && $website
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

task :stale do
  stale = website.stale_pages
  puts stale unless stale.empty?
end

def new_file title, dir = ".", date = false
  path = "#{title.strip.downcase.gsub(/\W+/, '-')}.html.md"

  t = Time.now
  noon = Time.local(t.year, t.month, t.day, 12)

  if date then
    date = case date
           when String
             case date
             when /today/i then
               noon
             when /tomorrow/i then
               noon + 86400
             else
               Time.parse(date)
             end
           when Time
             date
           else
             Time.now
           end

    path = "#{date.strftime '%Y-%m-%d'}-#{path}"
  end

  date ||= Time.now
  path = File.join dir, path

  open path, 'w' do |post|
    post.puts "---"
    post.puts "title: \"#{title}\""
    post.puts "date: #{date.iso8601}"
    post.puts "series: FI#{'X'}"
    post.puts "tags:"
    post.puts "- FI#{'X'}"
    post.puts "..."
    post.puts
  end

  path
end

desc "Begin a new dated post: rake new_post['title']"
task :new_post, :title do |t, args|
  dir   = ENV["DIR"]   || "."
  title = args[:title] || "new-post"
  date  = ENV["DATE"]  || :dated

  path = new_file title, dir, date

  warn "Created new post: #{path}"
end

desc "Begin a new page: rake new_page['title']"
task :new_page, :title do |t, args|
  dir = ENV["DIR"] || "."
  title = args[:title] || "new-post"

  path = new_file title, dir

  warn "Created new file: #{path}"
end

desc "Run a webserver and build on the fly."
task :run do
  require 'zenweb/extensions'
  require 'webrick'
  require 'thread'

  module Rake
    class FileTask
      def clear_timestamp
        @timestamp = nil
        prerequisite_tasks.each(&:clear_timestamp)
      end
    end
  end

  # TODO: implement a watcher or something... this is annoying
  class ZenwebBuilder < WEBrick::HTTPServlet::FileHandler
    @@semaphore = Mutex.new

    def service req, res
      @@site ||= @@semaphore.synchronize { website }

      url = req.path
      target_path = File.join(".site", url)

      target_path = File.join target_path, "index.html" if
        File.directory? target_path

      task = Rake.application[target_path] rescue nil

      warn "NOTE: No file found for #{url}" unless task

      if task then
        if task.needed? then
          unless system "#{Gem.ruby} -S rake -q clean generate" then
            warn "WARNING: couldn't run 'rake clean generate' properly, exited: %p" % [$?]
          end
        end

        @@site = $website = nil
        Rake.application = Rake::Application.new # reset
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

website if ENV['DEBUG']

desc "Debug the generation of a file. Takes a F=path arg or defaults to index.html.erb."
task :debug do
  site = website

  path = ENV['PAGE'] || ENV['F'] || ENV['FILE'] || "index.html.erb"

  page = site.pages[path]

  if page
    page.generate

    puts
    puts File.read page.url_path
  else
    fail "Could not find F=%p" % [path]
  end
end

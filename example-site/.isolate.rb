require "isolate"

Isolate.now! :path => ".isolate", :system => false do
  gem 'rack'
  # gem 'jekyll'
  # gem 'rdiscount'
  # gem 'pygments.rb'
  # gem 'RedCloth'
  # gem 'haml', '>= 3.1'
  # gem 'compass', '>= 0.11'
  # gem 'rubypants'
  gem 'rb-fsevent'
  # gem 'stringex'

  # I know I'm using these:
  gem 'rake',     '~> 0.9'
  gem 'less',     '~> 1.2'
  gem 'coderay',  '~> 1.0'
  gem 'kramdown', '~> 0.13'
end

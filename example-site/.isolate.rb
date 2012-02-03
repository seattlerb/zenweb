require "isolate"

Isolate.now! :path => ".isolate", :system => false do
  gem 'rake',     '~> 0.9'
  gem 'less',     '~> 1.2'
  gem 'coderay',  '~> 1.0'
  gem 'kramdown', '~> 0.13'
end

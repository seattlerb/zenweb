require "isolate"

Isolate.now! :path => ".isolate", :system => false do
  gem 'zenweb',   '~> 3.0.0.b1'
end

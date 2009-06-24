# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :seattlerb

Hoe.spec 'zenweb' do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'

  clean_globs.push(*"testhtml docshtml httpd.conf httpd.pid *.log".split)
end

task :docs do
  ruby "-w -Ilib bin/zenweb docs"
end

# TODO:
# apache: docs
# grep -v CustomLog $$(httpd -V | grep SERVER_CONFIG_FILE | cut -f 2 -d= | cut -f 2 -d\") > httpd.conf; httpd -X -d $$PWD/docshtml -f $$PWD/httpd.conf  -c "PidFile $$PWD/httpd.pid" -c "Port 8080" -c "ErrorLog $$PWD/error.log" -c "TransferLog $$PWD/access.log" -c "DocumentRoot $$PWD/docshtml"

# vim: syntax=ruby

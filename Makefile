RUBY?=ruby
RUBYFLAGS?=-w -I.

all: testfull

testfull: requirements syntax test

test:
	$(RUBY) $(RUBYFLAGS) TestZenWeb.rb $(TEST)

force:
docs: force
	$(RUBY) $(RUBYFLAGS) -w -I. ZenWeb.rb docs

clean:
	find . -name \*~ -exec rm {} \;
	rm -rf testhtml docshtml httpd.conf httpd.pid error.log access.log

apache: docs
	grep -v CustomLog $$(httpd -V | grep SERVER_CONFIG_FILE | cut -f 2 -d= | cut -f 2 -d\") > httpd.conf; httpd -X -d $$PWD/docshtml -f $$PWD/httpd.conf  -c "PidFile $$PWD/httpd.pid" -c "Port 8080" -c "ErrorLog $$PWD/error.log" -c "TransferLog $$PWD/access.log" -c "DocumentRoot $$PWD/docshtml"

.PHONY: test syntax


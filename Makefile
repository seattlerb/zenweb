RUBY?=ruby18
RDOC?=rdoc18
RUBYFLAGS?=-v

all: docs

test: requirements syntax 
	$(RUBY) $(RUBYFLAGS) -w -I. TestZenWeb.rb $(TEST)

syntax:
	$(RUBY) -wc ZenWeb.rb
	$(RUBY) -wc TestZenWeb.rb
	@for f in ZenWeb/*.rb; do \
	  echo checking requires $$f; \
	  $(RUBY) -w $$f; \
	done

requirements:
	@$(RUBY) -e "require 'test/unit/testcase'; \
	          puts 'Requirements OK';" 2> /dev/null \
	   || (echo "*** You need to install Test::Unit to run tests"; \
	       echo "*** download from http://www.ruby-lang.org/raa/"; \
	       false)

force:
docs: force
	$(RUBY) $(RUBYFLAGS) -w -I. ZenWeb.rb docs

rdoc: force
	$(RDOC)

PREFIX=/usr/local
install:
	@where=`$(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]'`; \
	echo "installing ZenWeb.rb     in $$where"; \
	cp -f ZenWeb.rb $$where; \
	echo "installing ZenWeb        in $$where"; \
	rm -rf $$where/ZenWeb; cp -fr ZenWeb $$where; \
	echo "installing ZenWebpage.rb in $(PREFIX)/bin"; \
	cp -f ZenWebpage.rb $(PREFIX)/bin; \
	echo "installing ZenWebsite.rb in $(PREFIX)/bin"; \
	cp -f ZenWebsite.rb $(PREFIX)/bin; \
	echo "symlinking ZenWebpage.rb to $(PREFIX)/bin/zenwebpage"; \
	ln -sf ./ZenWebpage.rb $(PREFIX)/bin/zenwebpage; \
	echo "symlinking ZenWebsite.rb to $(PREFIX)/bin/zenwebsite"; \
	ln -sf ./ZenWebsite.rb $(PREFIX)/bin/zenwebsite; \
	echo "symlinking ZenWeb.rb     to $(PREFIX)/bin/zenweb"; \
	ln -sf $$where/ZenWeb.rb $(PREFIX)/bin/zenweb; \
	echo "fixing permissions on everything"; \
	chmod 755 $$where/ZenWeb.rb $(PREFIX)/bin/ZenWebpage.rb $(PREFIX)/bin/ZenWebsite.rb; \
	echo Installed

# install -BdSv

clean:
	find . -name \*~ -exec rm {} \;
	rm -rf testhtml docshtml httpd.conf httpd.pid error.log access.log

apache: docs
	grep -v CustomLog $$(httpd -V | grep SERVER_CONFIG_FILE | cut -f 2 -d= | cut -f 2 -d\") > httpd.conf; httpd -X -d $$PWD/docshtml -f $$PWD/httpd.conf  -c "PidFile $$PWD/httpd.pid" -c "Port 8080" -c "ErrorLog $$PWD/error.log" -c "TransferLog $$PWD/access.log" -c "DocumentRoot $$PWD/docshtml"

.PHONY: test syntax


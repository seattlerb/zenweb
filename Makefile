RUBY?=ruby
RUBYFLAGS?=

all: demo

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
demo: force
	$(RUBY) $(RUBYFLAGS) -w -I. ZenWeb.rb demo

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
	rm -rf testhtml demohtml

apache:
	sudo httpd -c "DocumentRoot $$PWD/demohtml"
# this doesn't quite work yet... argh... I want a private httpd to test with
#	httpd -X -d $$PWD -c "PidFile $$PWD/httpd.pid" -c "DocumentRoot $$PWD/demohtml" -c "Port 8080" -c "ErrorLog $$PWD/httpd-error.log"

.PHONY: test syntax


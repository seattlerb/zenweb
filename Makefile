
all: syntax

test: requirements syntax 
	ruby -w -I. TestZenWeb.rb $(TEST)

syntax:
	ruby -wc ZenWeb.rb
	ruby -wc TestZenWeb.rb
	@for f in ZenWeb/*.rb; do \
	  echo checking requires $$f; \
	  ruby -w $$f; \
	done

requirements:
	@ruby -e "require 'test/unit/testcase'; \
	          puts 'Requirements OK';" 2> /dev/null \
	   || (echo "*** You need to install Test::Unit to run tests"; \
	       echo "*** download from http://www.ruby-lang.org/raa/"; \
	       false)

force:
demo: force
	ruby -w -I. ZenWeb.rb demo

PREFIX=/usr/local
install:
	@where=`ruby -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]'`; \
	echo "installing ZenWeb.rb     in $$where"; \
	cp -f ZenWeb.rb $$where; \
	echo "installing ZenWeb        in $$where"; \
	rm -rf $$where/ZenWeb; cp -fr ZenWeb $$where; \
	echo "installing ZenWebpage.rb in $(PREFIX)/bin"; \
	cp -f ZenWebpage.rb $(PREFIX)/bin; \
	echo "symlinking ZenWebpage.rb to $(PREFIX)/bin/zenwebpage"; \
	ln -sf ./ZenWebpage.rb $(PREFIX)/bin/zenwebpage; \
	echo "symlinking ZenWeb.rb     to $(PREFIX)/bin/zenweb"; \
	ln -sf $$where/ZenWeb.rb $(PREFIX)/bin/zenweb; \
	echo Installed

clean:
	find . -name \*~ -exec rm {} \;
	rm -rf testhtml demohtml

apache:
	sudo httpd -c "DocumentRoot $$PWD/demohtml"
# this doesn't quite work yet... argh... I want a private httpd to test with
#	httpd -X -d $$PWD -c "PidFile $$PWD/httpd.pid" -c "DocumentRoot $$PWD/demohtml" -c "Port 8080" -c "ErrorLog $$PWD/httpd-error.log"

.PHONY: test syntax


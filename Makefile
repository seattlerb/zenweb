
all: syntax

clean:

syntax:
	ruby -wc ZenWeb.rb
	ruby -wc TestZenWeb.rb

test: syntax
	ruby -w -I. TestZenWeb.rb $(TEST)

force:
demo: force
	ruby -w -I. ZenWeb.rb demo

install:
	@where=`ruby -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]'`; echo installing in $$where; cp -f ZenWeb.rb $$where

clean:
	rm -rf *~ testhtml demohtml

.PHONY: test syntax

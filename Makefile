
all: syntax

clean:

syntax:
	ruby -wc ZenWeb.rb
	ruby -wc TestZenWeb.rb

test: syntax
	ruby -w -I. TestZenWeb.rb $(TEST)

install:
	@where=`ruby -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]'`; echo installing in $$where; cp -f ZenWeb.rb $$where

clean:
	rm -rf *~ testhtml xxxhtml

.PHONY: test syntax

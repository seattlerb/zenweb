
all: syntax

clean:

syntax:
	ruby -wc ZenWeb.rb
	ruby -wc TestZenWeb.rb

test:
	-TestZenWeb.rb

.PHONY: test syntax

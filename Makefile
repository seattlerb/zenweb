
all: syntax

clean:

syntax:
	ruby -wc ZenWeb.rb
	ruby -wc TestZenWeb.rb

test:
	ruby -w TestZenWeb.rb

.PHONY: test syntax

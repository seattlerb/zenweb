#!/bin/env python

from ZSSWebsite import DemoSite

# brought into __main__ for ZenWebsite
from ZSSWebsite import ZSSDocument, ZSSSiteMap, ZSSRawDocument

if __name__ == '__main__':
	DemoSite("SiteMap", "./demo", "./demohtml").renderSite()

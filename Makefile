.PHONY: dev build new clean help

HUGO := mise exec -- hugo

## dev: start dev server with drafts and live reload
dev:
	$(HUGO) server --buildDrafts --port 1313

## build: production build (no drafts)
build:
	$(HUGO) --minify

## new: create a new post — usage: make new name=my-post-title
new:
	$(HUGO) new content posts/$(name).md

## clean: remove build output
clean:
	rm -rf public/ resources/_gen/

## help: show this help
help:
	@grep -E '^## ' Makefile | sed 's/## //' | column -t -s ':'

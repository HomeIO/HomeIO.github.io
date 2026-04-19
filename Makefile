.PHONY: dev build new clean lint-css deploy help

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

## deploy: push to GitHub Pages
deploy:
	git push origin master

## lint-css: validate CSS syntax
lint-css:
	@python3 -c "\
	css = open('themes/homeio/static/css/style.css').read(); \
	depth = 0; errors = []; \
	for i, c in enumerate(css): \
	    if c == '{': depth += 1; \
	    elif c == '}': depth -= 1; \
	    if depth < 0: errors.append(f'Unmatched }} at line {css[:i].count(chr(10))+1}'); break; \
	if depth > 0: errors.append(f'Unclosed {{ — depth {depth} at end'); \
	[print(f'ERROR: {e}') for e in errors] or print('CSS braces OK'); \
	exit(1 if errors else 0)"

## help: show this help
help:
	@grep -E '^## ' Makefile | sed 's/## //' | column -t -s ':'

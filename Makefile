# Just a trivial makefile to shorten some common commands.

serve:
	pub run build_runner serve

build: docs
	pub run build_runner build --output web:build --release
	rm -rf gh-pages
	git clone --single-branch -b gh-pages \
			https://github.com/munificent/hauberk.git gh-pages
	cp build/* gh-pages

docs:
	dart bin/update_docs.dart

.PHONY: docs serve

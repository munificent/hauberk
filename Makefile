# Just a trivial makefile to shorten some common commands.

serve:
	pub run build_runner serve

build: docs
	pub run build_runner build --output web:build --release
	rm -rf gh-pages
	git clone --single-branch -b gh-pages \
			https://github.com/munificent/hauberk.git gh-pages
	mkdir -p gh-pages/debug
	cp build/* gh-pages
	cp build/debug/* gh-pages/debug

docs:
	dart bin/update_docs.dart

.PHONY: docs serve

# Just a trivial makefile to shorten some common commands.

docs:
	dart bin/update_docs.dart

serve:
	pub run build_runner serve

.PHONY: docs serve

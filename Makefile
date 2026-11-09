FLUTTER := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo "flutter")
DART := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm dart" || echo "dart")

.PHONY: setup gen analyze test check-docs check apk

setup:
	$(FLUTTER) pub get

gen:
	$(DART) run build_runner build --delete-conflicting-outputs

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

check-docs:
	$(DART) run tool/check_docs.dart

check: analyze test check-docs

apk:
	$(FLUTTER) build apk --debug

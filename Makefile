FLUTTER := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || echo "flutter")
DART := $(shell command -v fvm >/dev/null 2>&1 && echo "fvm dart" || echo "dart")

.PHONY: setup gen gen-check analyze test check-docs check apk

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

# Pastikan binding ObjectBox yang di-commit sesuai dengan entity.
gen-check:
	$(DART) run build_runner build --delete-conflicting-outputs
	git diff --exit-code -- lib/objectbox.g.dart lib/objectbox-model.json

check: analyze test check-docs gen-check

apk:
	$(FLUTTER) build apk --debug

# Keep the Makefile POSIX-compliant.  We currently allow hyphens in
# target names, but that may change in the future.
#
# See https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html.
.POSIX:

WEBEXT_DIR = extensions/webext
APPEXT_DIR = extensions/appext
PNPM_WEBEXT = pnpm -C $(WEBEXT_DIR)
PNPM_APPEXT = pnpm -C $(APPEXT_DIR)

build-js: build-js-webext build-js-appext

build-js-webext:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run build

build-js-appext:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run build

lint: md-lint swift-lint swiftformat-lint webext-lint appext-lint

md-lint:
	npx markdownlint .

swift-lint:
	swiftlint lint --strict --quiet

swiftformat-lint:
	swift format lint --recursive --strict .

webext-lint:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run lint

appext-lint:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run lint

# Keep the Makefile POSIX-compliant.  We currently allow hyphens in
# target names, but that may change in the future.
#
# See https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html.
.POSIX:

WEBEXT_DIR = extensions/webext
APPEXT_DIR = extensions/appext
PNPM_WEBEXT = pnpm -C $(WEBEXT_DIR)
PNPM_APPEXT = pnpm -C $(APPEXT_DIR)

init:
	git config core.hooksPath ./scripts/hooks

js-build: js-build-webext js-build-appext

js-build-webext:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run build

js-build-appext:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run build

lint: md-lint swift-lint swiftformat-lint webext-lint appext-lint

md-lint:
	npx markdownlint .

swift-lint: swiftlint-lint swiftformat-lint

swiftlint-lint:
	swiftlint lint --strict --quiet

swiftformat-lint:
	swift format lint --recursive --strict .

js-lint: webext-lint appext-lint

webext-lint:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run lint

appext-lint:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run lint

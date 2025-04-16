# Keep the Makefile POSIX-compliant.  We currently allow hyphens in
# target names, but that may change in the future.
#
# See https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html.
.POSIX:

WEBEXT_DIR = extensions/webext
APPEXT_DIR = extensions/appext
PNPM_WEBEXT = pnpm -C $(WEBEXT_DIR)
PNPM_APPEXT = pnpm -C $(APPEXT_DIR)
XCODEBUILD_ARGS_MACOS = -project safari-blocker.xcodeproj -scheme safari-blocker
XCODEBUILD_ARGS_IOS = -project safari-blocker.xcodeproj -scheme safari-blocker-ios -sdk iphonesimulator

init:
	git config core.hooksPath ./scripts/hooks

# Building

swift-build: swift-macos-build swift-ios-build

swift-macos-build:
	xcodebuild build $(XCODEBUILD_ARGS_MACOS) | xcbeautify -q

swift-ios-build:
	xcodebuild build $(XCODEBUILD_ARGS_IOS) | xcbeautify -q

js-build: js-build-webext js-build-appext

js-build-webext:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run build

js-build-appext:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run build

# Linting

lint: md-lint swift-lint js-lint

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

# Swiftlint analyze

swiftlint-analyze: swiftlint-macos-analyze swiftlint-ios-analyze

swiftlint-macos-analyze:
	xcodebuild clean build \
		$(XCODEBUILD_ARGS_MACOS) > compiler-macos.log \
		|| (cat compiler-macos.log && false)
	swiftlint analyze --strict --quiet --compiler-log-path=compiler-macos.log
	rm compiler-macos.log

swiftlint-ios-analyze:
	xcodebuild clean build \
		$(XCODEBUILD_ARGS_IOS) > compiler-ios.log \
		|| (cat compiler-ios.log && false)
	swiftlint analyze --strict --quiet --compiler-log-path=compiler-ios.log
	rm compiler-ios.log

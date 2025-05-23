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

# Init the repo and setup pre-commit hooks.
init:
	git config core.hooksPath ./scripts/hooks

# Building
##########

# Build both macOS and iOS apps
swift-build: swift-macos-build swift-ios-build

# Builds macOS app
swift-macos-build:
	xcodebuild build $(XCODEBUILD_ARGS_MACOS) | xcbeautify -q

# Builds iOS app
swift-ios-build:
	xcodebuild build $(XCODEBUILD_ARGS_IOS) | xcbeautify -q

# Builds both web and app extensions JS code
js-build: js-build-webext js-build-appext

# Builds web extension's JS code and copies to Resources
js-build-webext:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run build

# Builds app extension's JS code and copies to Resources
js-build-appext:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run build

# Linting
##########

# Runs all linters
lint: md-lint swift-lint js-lint

# Runs markdown linter
md-lint:
	npx markdownlint .

# Runs all linters for Swift code
swift-lint: swiftlint-lint swiftformat-lint

# Runs SwiftLint linter
swiftlint-lint:
	swiftlint lint --strict --quiet

# Runs swift-format linter
swiftformat-lint:
	swift format lint --recursive --strict .

# Runs all javascript linters
js-lint: webext-lint appext-lint

# Runs JS linter for the web extension's code
webext-lint:
	$(PNPM_WEBEXT) install && $(PNPM_WEBEXT) run lint

# Runs JS linter for the app extension's code
appext-lint:
	$(PNPM_APPEXT) install && $(PNPM_APPEXT) run lint

# SwiftLint analyze
#
# A separate section specifically for running SwiftLint analyze.
# It's more complicated since it requires building the apps first and then
# SwiftLint will analyze the build log.

# Runs SwiftLint analyze for both macOS and iOS apps
swiftlint-analyze: swiftlint-macos-analyze swiftlint-ios-analyze

# Runs SwiftLint analyze for macOS app
swiftlint-macos-analyze:
	xcodebuild clean build \
		$(XCODEBUILD_ARGS_MACOS) > compiler-macos.log \
		|| (cat compiler-macos.log && false)
	swiftlint analyze --strict --quiet --compiler-log-path=compiler-macos.log
	rm compiler-macos.log

# Runs SwiftLint analyze for iOS app
swiftlint-ios-analyze:
	xcodebuild clean build \
		$(XCODEBUILD_ARGS_IOS) > compiler-ios.log \
		|| (cat compiler-ios.log && false)
	swiftlint analyze --strict --quiet --compiler-log-path=compiler-ios.log
	rm compiler-ios.log

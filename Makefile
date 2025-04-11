# Keep the Makefile POSIX-compliant.  We currently allow hyphens in
# target names, but that may change in the future.
#
# See https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html.
.POSIX:

# .PHONY: default

lint: md-lint swift-lint swiftformat-lint

md-lint:
	npx markdownlint .

swift-lint:
	swiftlint

swiftformat-lint:
	swift format lint --recursive --strict .
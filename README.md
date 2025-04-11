# Safari Content Blocker

Very simple macOS and iOS apps for debugging Safari content blocking rules.

This is also a showcase of how to use [SafariConverterLib][converter] to build
a Safari content blocker.

[converter]: https://github.com/AdguardTeam/SafariConverterLib

## Prepare

1. XCode is required to build it.
1. Run `git clone https://github.com/AdguardTeam/SafariConverterLib.git safari-converter-lib` to clone the [SafariConverterLib][converter] project.
1. Edit the file `filters/filter.txt` and put the rules you'd like to test
   there.

### macOS app

1. In order to use the app on macOS, enable [developer mode][safaridevelop] in
   Safari and [allow unsigned extensions][unsigned] in Developer Options.
1. Build and run the app, target `safari-blocker`.

[safaridevelop]: https://developer.apple.com/documentation/safari-developer-tools/enabling-developer-features
[unsigned]: https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension#3744467

### iOS app

1. If you use a Simulator, it will be enought to build and run `safari-blocker-ios`.

## Development

### Prerequisites

- Install [Node.js][nodejs]: recommend to use [nvm][nvm] for that.
- Install [pnpm][pnpm]: `brew install pnpm`.
- Install [SwiftLint][swiftlint]: `brew install swiftlint`.
- Install [xcbeautify][xcbeautify]: `brew install xcbeautify`.

[nodejs]: https://nodejs.org/
[nvm]: https://github.com/nvm-sh/nvm
[pnpm]: https://pnpm.io/
[swiftlint]: https://github.com/realm/SwiftLint
[xcbeautify]: https://github.com/cpisciotta/xcbeautify

Run `make init` to setup pre-commit hooks.

### Building

Use XCode to build and run the apps.

- `safari-blocker` - the macOS version.
- `safari-blocker-ios` - the iOS version.

To build the browser extensions code run `make js-build`.

### Developer documentation

Please refer to [./.windsurfrules](./.windsurfrules) for developer
documentation and guidelines.

For the browser extensions, please refer to their respective README files:

- [appext/README.md](./appext/README.md)
- [webext/README.md](./webext/README.md)

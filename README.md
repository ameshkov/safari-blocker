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

- Install [Node.js][nodejs].
- Install [pnpm][pnpm].
- Install [SwiftLint][swiftlint].

[nodejs]: https://nodejs.org/
[pnpm]: https://pnpm.io/
[swiftlint]: https://github.com/realm/SwiftLint

Run `make init` to setup pre-commit hooks.

## TODO

- [] Add linters (markdownlint, swiftlint, swiftformat)
- [] Explain how to build and run the apps
- [] Explain how to build and add extensions
- [] Explain how extensions are added to the project

- [] Explain resources

```text
  D70B17D02D11939C000A827C /* web-extension */ = {
   isa = PBXFileSystemSynchronizedRootGroup;
   exceptions = (
    D70B17EC2D11939C000A827C /* Exceptions for "web-extension" folder in "web-extension" target */,
   );
   explicitFolders = (
    Resources/_locales,
    Resources/assets,
    Resources/pages,
   );
   path = "web-extension";
   sourceTree = "<group>";
  };
```

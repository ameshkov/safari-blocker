# Safari Content Blocker

Very simple macOS and iOS apps for debugging Safari content blocking rules.

This is also a showcase of how to use [SafariConverterLib][converter] to build
a Safari content blocker.

[converter]: https://github.com/AdguardTeam/SafariConverterLib

<p align="center">
  <img src="https://cdn.adtidy.org/website/github.com/safari-blocker/safari-blocker.png?mw=1200" width="800" alt="safari-blocker"/>
</p>

## Prepare

1. XCode 16.3 or newer is required to build it.
2. Change "Development Team" in the Project settings.
3. Change bundle IDs of each target and app groups, i.e. replace all
   occurrences in all files: `dev.ameshkov` -> `dev.yourname`.
4. Edit the file `filters/filter.txt` and put the rules you'd like to test
   there.

### Using local SafariConverterLib

If you want to use local version of [SafariConverterLib][converter], please do the following:

1. Clone the [SafariConverterLib][converter] project to `/safari-converter-lib`:

   ```sh
   git clone https://github.com/AdguardTeam/SafariConverterLib.git safari-converter-lib
   ```

2. Change path to converter JS library in [extensions/appext/package.json] and
   in [extensions/webext/package.json]:

   ```json
   "dependencies": {
      "@adguard/safari-extension": "file:../../safari-converter-lib/Extension"
   }
   ```

3. Run `make js-build` to rebuild the extensions.

4. Open XCode, open `safari-blocker` project, go to `Package dependencies`, remove `ContentBlockerConverter` package and add its local version instead. Add the library to target `content-blocker-service`.

[extensions/appext/package.json]: ./extensions/appext/package.json
[extensions/webext/package.json]: ./extensions/webext/package.json

### macOS app

1. In order to use the app on macOS, enable [developer mode][safaridevelop] in
   Safari and [allow unsigned extensions][unsigned] in Developer Options.
2. Build and run the app, target `safari-blocker`.

[safaridevelop]: https://developer.apple.com/documentation/safari-developer-tools/enabling-developer-features
[unsigned]: https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension#3744467

### iOS app

1. If you use a Simulator, it will be enough to build and run `safari-blocker-ios`.

## Development

### Prerequisites

- Swift 6 or newer.
- Install [Node.js][nodejs]: recommend to use [nvm][nvm] for that.
- Install [pnpm][pnpm]: `brew install pnpm`.
- Install [SwiftLint][swiftlint]: `brew install swiftlint`.
- Install [xcbeautify][xcbeautify]: `brew install xcbeautify`.
- Install [markdownlint-cli][markdownlint]: `npm install -g markdownlint-cli`.

[nodejs]: https://nodejs.org/
[nvm]: https://github.com/nvm-sh/nvm
[pnpm]: https://pnpm.io/
[swiftlint]: https://github.com/realm/SwiftLint
[xcbeautify]: https://github.com/cpisciotta/xcbeautify
[markdownlint]: https://www.npmjs.com/package/markdownlint-cli

Run `make init` to setup pre-commit hooks.

### Building

Use XCode 16.3 or newer to build and run the apps.

- `safari-blocker` - the macOS version.
- `safari-blocker-ios` - the iOS version.

To build the browser extensions code, run `make js-build`.

### Developer documentation

Please refer to [./DEVELOPMENT.md][devdoc] for developer documentation and
guidelines.

If you're using an AI-enabled IDE (Windsurf/Cursor/Copilot/etc), use this
document as a rules file, for example:

```sh
ln -s ./DEVELOPMENT.md .windsurfrules
```

For the browser extensions, please refer to their respective README files:

- [appext/README.md](./appext/README.md)
- [webext/README.md](./webext/README.md)

[devdoc]: ./DEVELOPMENT.md

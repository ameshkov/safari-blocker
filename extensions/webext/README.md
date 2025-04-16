# Web Extension

This project is a sample [Safari Web Extension][safariwebext] that demonstrates
how to integrate [SafariConverterLib][safariconverterlib] into the extension.

In most of the cases you would prefer to build a web extension, but there are
some cases where the old [App Extension][appext] can do more.

[safariconverterlib]: https://github.com/AdguardTeam/SafariConverterLib
[safariwebext]: https://developer.apple.com/documentation/safariservices/creating-a-safari-web-extension
[appext]: ../appext/README.md

## Project structure

- `/_locales` - Localization files.
- `/assets` - Static assets (images and CSS).
- `/pages` - HTML pages that are part of the extension.
- `/src` - Source files.
    - `/src/background` - Background page code.
    - `/src/content` - Content script code.
    - `/src/common` - Common code for both background and content scripts.
- `/manifest.json` - extension manifest.

The build results will be copied to `web-extension/Resources` and
`web-extension-ios/Resources`. Please note, that when setting up these folders
you may need update the `explicitFolders` in the `xcodeproj` file and add
explicit resource folders there, this way the build system will include them in
the build and retain the directory structure. Otherwise, you'll have to add
every file manually.

```text
explicitFolders = (
 Resources/_locales,
 Resources/images,
 Resources/assets,
 Resources/pages,
);
```

## How does it work

The extension implements a simple algorithm to lookup and apply "advanced"
content blocking rules to web pages.

> We call the rules "advanced" because there is no similar alternative provided
> by Safari Content Blocking API and the only way to apply them is to interpret
> these rules with a JS script.

The algorithm consists of the following stages:

- Content script requests the background script for the rules to apply to the
  current page.
- Background script looks up the rules in a local cache and if nothing found
  there it requests the rules from the native extension host.
- Native extension host prepares a set of rules for the page and passes them
  back to the background script.
- Background script returns the rules to the content script.
- Content script uses `ContentScript` object provided by
  [SafariConverterLib][safariconverterlib] to apply the rules.

## How to build

1. `pnpm install` - Install dependencies.
2. `pnpm build` - Build the project and copy the generated script to the
    extension resources folder.
3. `pnpm lint` - Run ESLint to check the code for errors and style violations.

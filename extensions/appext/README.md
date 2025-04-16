# App Extension

This project is a sample [Safari App Extension][safariappext] that demonstrates
how to integrate [SafariConverterLib][safariconverterlib] into the extension.

In most of the cases you should prefer building a [Web Extension][webext], but
there are still some where App Extension can do more:

- App Extension can implement a "blocked" counter, i.e. indicate the number of
  requests blocked by Safari Content Blocker. See [ToolbarData][toolbardata] for
  more details.
- App Extension is generally a little faster than Web Extension, i.e. messages
  between the content script and the native extension host are faster.

However, the major drawback is that App Extensions are **not supported on iOS**.

[safariconverterlib]: https://github.com/AdguardTeam/SafariConverterLib
[safariappext]: https://developer.apple.com/documentation/safariservices/building-a-safari-app-extension
[webext]: ../webext/README.md
[toolbardata]: ../../app-extension/ToolbarData.swift

## Project structure

- `/src` - Source files.

Generally, the only part of the App Extension is its content script.

The build results will be copied to `app-extension/Resources`.

## How does it work

The extension implements a simple algorithm to lookup and apply "advanced"
content blocking rules to web pages.

> We call the rules "advanced" because there is no similar alternative provided
> by Safari Content Blocking API and the only way to apply them is to interpret
> these rules with a JS script.

The algorithm consists of the following stages:

- Content script requests the native host for the rules to apply to the current
  page.
- Native extension host prepares a set of rules for the page and passes them
  back to the content script.
- Content script uses `ContentScript` object provided by
  [SafariConverterLib][safariconverterlib] to apply the rules.

## How to build

1. `pnpm install` - Install dependencies.
2. `pnpm build` - Build the project and copy the generated script to the
    extension resources folder.
3. `pnpm lint` - Run ESLint to check the code for errors and style violations.

# Safari Blocker

Safari Blocker is a project that showcases how to use
[SafariConverterLib][converter] to build a Safari content blocker. It provides
macOS and iOS apps that can be used to debug AdGuard rules in Safari.

[converter]: https://github.com/AdguardTeam/SafariConverterLib

## General Code Style & Formatting

1. Use standard Swift formatting and style guidelines.
2. Use 4 spaces for indentation.
3. When writing class and function comments, prefer `///` style comments. In
   this case, you should use proper markdown formatting.
4. When writing inline comments, prefer `//` style comments.
5. In the case of comments, try to keep line length under 80 characters. In the
   case of code, it should be under 100.
6. Avoid comments on the same line as the code; place them on a previous line.

## Build Instructions

Read the [Makefile](./Makefile) for build instructions.

## Code Organization

This project is a Safari content blocking app and it consists of the following parts.

### `content-blocker-service`

Located in `/content-blocker-service`. This is a framework shared by all app
components that implements the app's business logic.

- `ContentBlockerService.swift` - the API for `safari-blocker` to convert
  rules to the format that extensions can understand. The rules are then saved
  to the shared location (using `GroupIdentifier` to get access to it).
- `ContentBlockerExtensionRequestHandler.swift` - the API for Safari content
  blocking extensions (`content-blocker` and `content-blocker-ios`) to load
  rules from the shared location (using `GroupIdentifier` to get access to it).
- `WebExtensionRequestHandler.swift` - the API for Safari Web Extensions
  (`web-extension` and `web-extension-ios`) to lookup "advanced rules" for a
  given URL.
- `GroupIdentifier.swift` - shared logic for group identifiers. Basically, this
  is a singleton that holds shared group identifier.

It uses [SafariConverterLib][converter] to convert the rules to the format that
extensions can understand.

There are two file formats:

- Safari Content Blocker JSON. It is consumed by `content-blocker` and
  `content-blocker-ios`.
- Advanced rules (text format with AdGuard rules syntax + binary format for
  serialized `WebExtension`). These rules are serialized to the shared location
  by calling `WebExtension.buildFilterEngine`. These serialized rules are
  later consumed by `web-extension` (or `web-extension-ios`).

### `safari-blocker` and `safari-blocker-ios`

Located in `/safari-blocker` and `safari-blocker-ios`. These are similar apps
with the only difference being that `safari-blocker` is for macOS and
`safari-blocker-ios` is for iOS.

The UI is simply a `TextEditor` for user input. The user input is either text
of the rules in AdGuard syntax, Safari syntax, or URLs of the filter lists with
rules (the user can make a choice in the UI).

The rules are then retrieved and converted to the format that extensions can
understand (using `content-blocker-service`).

### `content-blocker` and `content-blocker-ios`

Located in `/content-blocker` and `content-blocker-ios`. These are similar apps
with the only difference being that `content-blocker` is for macOS and
`content-blocker-ios` is for iOS.

The app is a Safari content blocking extension which simply loads JSON files
with Safari rules from the shared location. All the logic is implemented in
`content-blocker-service` (see `ContentBlockerExtensionRequestHandler.swift`).

### `web-extension` and `web-extension-ios`

Located in `/web-extension` and `web-extension-ios`. These are similar apps
with the only difference being that `web-extension` is for macOS and
`web-extension-ios` is for iOS.

The app is a Safari Web Extension which consists of several parts.

- `SafariWebExtensionHandler.swift` - implements `NSExtensionRequestHandling`
  and processes requests from the extension's background page. It delegates all
  that to `content-blocker-service` (see `WebExtensionRequestHandler.swift`).
- `Resources` contains the code of the actual browser extension. However, the
  code in this folder is generated and the actual source code is located in
  the `/extensions/webext` folder. Refer to `/extensions/webext/README.md` for
  the details on how it is structured and built.

The basic logic is the following:

1. Extension's content script requests rules for the current page.
2. Extension's background page receives the request and if no rules are found in
   the cache, sends the request further to `SafariWebExtensionHandler`.
3. `SafariWebExtensionHandler` receives the request and delegates it to
   `content-blocker-service`.
4. `content-blocker-service` uses `WebExtension` singleton to lookup the rules
   for the current page.

### `app-extension`

Located in `/app-extension`. This is a Safari App Extension implementation and
it is only compatible with macOS and `safari-blocker`.

- `SafariExtensionHandler.swift` - implements `SFSafariExtensionHandler` and
  handles incoming messages from a web page.
- `Resources` contains the code of the content script (`SFSafariContentScript`).
  However, the code there is generated and the actual source code is located in
  the `/extensions/appext` folder. Refer to `/extensions/appext/README.md` for
  the details on how it is structured and built.

The basic logic is the following:

1. Extension's content script requests rules for the current page.
2. `SafariExtensionHandler` receives the request and delegates it to
   `content-blocker-service`.
3. `content-blocker-service` uses `WebExtension` singleton to lookup the rules
   for the current page.
4. `SafariExtensionHandler` returns the rules to the extension's content script.

### `extensions`

Located in `/extensions`. This folder contains the actual source code of the
browser extensions.

- `extensions/appext` - the source code of Safari App Extension's content
  script. Refer to `/extensions/appext/README.md` for the details on how it is structured and built.
- `extensions/webext` - the source code of Safari Web Extension. Refer to
  `/extensions/webext/README.md` for the details on how it is structured and
  built.

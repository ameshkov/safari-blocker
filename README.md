# Safari Content Blocker

A very simple macOS app for debugging Safari content blocking rules.

## How to use it

1. Go to **Package Dependencies** in Xcode and configure location for
   `ContentBlockerConverter` package. You can point it to its
   [Github repo][converter] or clone it and specify a local path.
1. Edit the file `filters/filter.txt` and put the rules you'd like to test
   there.
1. Enable [developer mode][safaridevelop] in Safari and
   [allow unsigned extensions][unsigned] in Developer Options.
1. Build and run the app.

[converter]: https://github.com/AdguardTeam/SafariConverterLib
[safaridevelop]: https://developer.apple.com/documentation/safari-developer-tools/enabling-developer-features
[unsigned]: https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension#3744467

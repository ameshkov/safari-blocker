# Safari Content Blocker

Very simple macOS and iOS apps for debugging Safari content blocking rules.

## Prepare

1. XCode is required to build it.
1. Run `git clone https://github.com/AdguardTeam/SafariConverterLib.git safari-converter-lib` to clone the [SafariConverterLib][converter] project.
1. Edit the file `filters/filter.txt` and put the rules you'd like to test
   there.

[converter]: https://github.com/AdguardTeam/SafariConverterLib

## macOS

1. Enable [developer mode][safaridevelop] in Safari and
   [allow unsigned extensions][unsigned] in Developer Options.
1. Build and run the app, target `safari-blocker`.

[safaridevelop]: https://developer.apple.com/documentation/safari-developer-tools/enabling-developer-features
[unsigned]: https://developer.apple.com/documentation/safariservices/running-your-safari-web-extension#3744467

## iOS

1. If you use a Simulator, it will be enought to build and run `safari-blocker-ios`.

## TODO

* [] Add linters (markdownlint, swiftlint, swiftformat)
* [] Explain how to build and run the apps
* [] Explain how to build and add extensions
* [] Explain how extensions are added to the project

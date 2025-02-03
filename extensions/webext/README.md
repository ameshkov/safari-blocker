# App Extension

This project is a sample Safari Web Extension that demonstrates how to integrate
[SafariConverterLib][safariconverterlib] into the extension.

[safariconverterlib]: https://github.com/AdguardTeam/SafariConverterLib

## How to build

1. `pnpm install` - Install dependencies.
2. `pnpm build` - Build the project and copy the generated script to the
    extension resources folder.
3. `pnpm lint` - Run ESLint to check the code for errors and style violations.

It may be necessary to update the `explicitFolders` in the `xcodeproj` file and
add explicit resource folders there, this way the build system will include
them in the build and retain the directory structure.

```text
explicitFolders = (
 Resources/_locales,
 Resources/images,
 Resources/assets,
 Resources/pages,
);
```

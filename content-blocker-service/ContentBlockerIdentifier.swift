//
//  ContentBlockerIdentifier.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 13/10/2025.
//

/// ContentBlockerIdentifier provides access to the content blocker extension
/// identifier used for reloading content blocker rules.
///
/// This class implements the singleton pattern to ensure consistent access to
/// the content blocker identifier throughout the application. The identifier is
/// derived from the app's bundle identifier and is platform-specific.
public final class ContentBlockerIdentifier {
    /// Shared singleton instance of ContentBlockerIdentifier.
    public static let shared = ContentBlockerIdentifier()

    /// The content blocker identifier string used to reload content blocker rules.
    public let value: String

    /// Initializes a new instance of the ContentBlockerIdentifier class.
    private init() {
        // Derive the content blocker identifier from the bundle identifier
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Unable to get bundle identifier")
        }

        // The content blocker extension has a specific suffix based on platform
        #if os(macOS)
        // For macOS, the content blocker identifier is the base app ID + ".content-blocker"
        // e.g., "dev.adguard.safari-blocker-mac.TEAM"
        //  -> "dev.adguard.safari-blocker-mac.TEAM.content-blocker"
        let contentBlockerSuffix = ".content-blocker"
        #elseif os(iOS)
        // For iOS, the content blocker identifier is the base app ID + ".content-blocker-ios"
        // e.g., "dev.adguard.safari-blocker-mobile.TEAM"
        //  -> "dev.adguard.safari-blocker-mobile.TEAM.content-blocker-ios"
        let contentBlockerSuffix = ".content-blocker-ios"
        #else
        fatalError("Unsupported platform")
        #endif

        // If running from the main app, append the suffix
        // If already running from an extension, use the bundle identifier as-is
        if bundleIdentifier.contains(".content-blocker") {
            self.value = bundleIdentifier
        } else {
            self.value = bundleIdentifier + contentBlockerSuffix
        }
    }
}

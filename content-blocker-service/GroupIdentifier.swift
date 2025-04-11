//
//  GroupIdentifier.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 01/02/2025.
//

/// GroupIdentifier provides access to the app group identifier used for sharing data
/// between the main app and its extensions.
///
/// This class implements the singleton pattern to ensure consistent access to the
/// app group identifier throughout the application. The group identifier is used to
/// access the shared container where content blocker rules are stored.
public final class GroupIdentifier {
    /// Shared singleton instance of GroupIdentifier.
    public static let shared = GroupIdentifier()

    /// The app group identifier string used to access the shared container.
    public let value: String

    /// Private initializer that sets the appropriate group identifier based on platform.
    ///
    /// On macOS, it reads the team identifier prefix from the Info.plist and constructs
    /// the group identifier. On iOS, it uses a hardcoded group identifier.
    private init() {
        #if os(macOS)
        if let teamIdentifierPrefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String
        {
            value = "\(teamIdentifierPrefix)group.dev.adguard.safari-blocker"
        } else {
            fatalError("AppIdentifierPrefix is not set in Info.plist")
        }
        #else
        value = "group.dev.adguard.safari-blocker"
        #endif
    }
}

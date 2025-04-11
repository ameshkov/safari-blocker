//
//  GroupIdentifier.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 01/02/2025.
//

// TODO(ameshkov): Add comment
public final class GroupIdentifier {
    public static let shared = GroupIdentifier()

    public let value: String

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

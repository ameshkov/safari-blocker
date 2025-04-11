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
        let teamIdentifierPrefix = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String
        if teamIdentifierPrefix == nil {
            fatalError("AppIdentifierPrefix is not set in Info.plist")
        } else {
            value = "\(teamIdentifierPrefix!)group.dev.adguard.safari-blocker"
        }
        #else
        value = "group.dev.adguard.safari-blocker"
        #endif
    }
}

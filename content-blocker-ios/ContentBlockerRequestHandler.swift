//
//  ContentBlockerRequestHandler.swift
//  content-blocker-ios
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import content_blocker_service

public class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    public func beginRequest(with context: NSExtensionContext) {
        ContentBlockerExtensionRequestHandler.handleRequest(
            with: context,
            groupIdentifier: GroupIdentifier.shared.value
        )
    }
}

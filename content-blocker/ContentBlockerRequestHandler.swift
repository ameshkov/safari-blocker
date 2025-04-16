//
//  ContentBlockerRequestHandler.swift
//  content-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import Foundation
import content_blocker_service

public class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    public func beginRequest(with context: NSExtensionContext) {
        ContentBlockerExtensionRequestHandler.handleRequest(
            with: context,
            groupIdentifier: GroupIdentifier.shared.value
        )
    }
}

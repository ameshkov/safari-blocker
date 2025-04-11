//
//  SafariWebExtensionHandler.swift
//  web-extension-ios
//
//  Created by Andrey Meshkov on 11/04/2025.
//

import content_blocker_service

public class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    public func beginRequest(with context: NSExtensionContext) {
        WebExtensionRequestHandler.beginRequest(with: context)
    }
}

//
//  SafariWebExtensionHandler.swift
//  web-extension-ios
//
//  Created by Andrey Meshkov on 11/04/2025.
//

import SafariServices
import content_blocker_service

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        WebExtensionRequestHandler.beginRequest(with: context)
    }
}

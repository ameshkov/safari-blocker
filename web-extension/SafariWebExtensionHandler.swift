//
//  SafariWebExtensionHandler.swift
//  web-extension
//
//  Created by Andrey Meshkov on 17/12/2024.
//

import SafariServices
import content_blocker_service

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        WebExtensionRequestHandler.beginRequest(with: context)
    }
}

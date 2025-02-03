//
//  AppExtension.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 02/02/2025.
//
// This class acts as a centralized manager for the WebExtension instance used by the Safari content blocker.
// Since there can be multiple instances of SafariExtensionHandler, using a singleton here ensures that they
// all refer to the same WebExtension, preventing duplicate initialization and potential conflicts.

import content_blocker_service

// Using a singleton pattern because several SafariExtensionHandler instances might exist.
class AppExtension {
    // The shared instance of AppExtension, accessible throughout the app.
    static let shared = AppExtension()

    // The webExtension property holds an instance of WebExtension,
    // which provides the core functionality for interacting with the content blocker service.
    let webExtension: WebExtension

    // Private initializer to enforce the singleton pattern.
    // Initializes the webExtension using a group identifier, ensuring correct sharing and access.
    private init() {
        // Retrieve the group identifier from GroupIdentifier, then create a new WebExtension instance.
        webExtension = WebExtension(groupIdentifier: GroupIdentifier.shared.value)
    }

    // TODO(ameshkov): !!! Implement caching logic here.
}

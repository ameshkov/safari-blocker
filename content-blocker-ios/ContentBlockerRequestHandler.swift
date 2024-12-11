//
//  ContentBlockerRequestHandler.swift
//  content-blocker-ios
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import UIKit
import MobileCoreServices
import content_blocker_service

let GROUP_ID = "group.dev.adguard.safari-blocker"

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        ContentBlockerExtension.handleRequest(with: context, groupIdentifier: GROUP_ID)
    }

}

//
//  ContentBlockerRequestHandler.swift
//  content-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import Foundation
import content_blocker_service

let GROUP_ID: String = {
    let teamIdentifierPrefix: String = Bundle.main.infoDictionary?["AppIdentifierPrefix"]! as! String
    return "\(teamIdentifierPrefix)group.dev.adguard.safari-blocker"
}()

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        ContentBlockerExtension.handleRequest(with: context, groupIdentifier: GROUP_ID)
    }

}

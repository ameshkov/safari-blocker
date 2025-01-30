//
//  SafariWebExtensionHandler.swift
//  web-extension
//
//  Created by Andrey Meshkov on 17/12/2024.
//

import SafariServices
import os.log
import content_blocker_service

let GROUP_ID: String = {
    let teamIdentifierPrefix: String = Bundle.main.infoDictionary?["AppIdentifierPrefix"]! as! String
    return "\(teamIdentifierPrefix)group.dev.adguard.safari-blocker"
}()

/// WebExtension must be declared as a static property because SafariWebExtensionHandler is created on every request.
///
/// TODO(ameshkov): !!! Comment
let WEB_EXTENSION = WebExtension(groupIdentifier: GROUP_ID)

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    override init() {
        super.init()
    }

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        var message = getMessage(from: request)

        if message == nil {
            context.completeRequest(returningItems: [])

            return
        }

        let nativeStart = Int64(Date().timeIntervalSince1970 * 1000)

        let payload = message?["payload"] as? [String: Any] ?? [:]
        if let urlString = payload["url"] as? String {
            if let url = URL(string: urlString) {
                if let configuration = WEB_EXTENSION.lookup(for: url) {
                    message?["payload"] = convertToPayload(configuration)
                }
            }
        }

        if var trace = message?["trace"] as? [String: Int64] {
            trace["nativeStart"] = nativeStart
            trace["nativeEnd"] = Int64(Date().timeIntervalSince1970 * 1000)
            message?["trace"] = trace // Reassign the modified dictionary back
        }

        let response = createResponse(with: message!)

        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }

    private func convertToPayload(_ configuration: WebExtension.Configuration) -> [String: Any] {
        var payload: [String: Any] = [:]
        payload["css"] = configuration.css
        payload["extendedCss"] = configuration.extendedCss
        payload["js"] = configuration.js
        
        var scriptlets: [[String: Any]] = []
        for scriptlet in configuration.scriptlets {
            var scriptletData: [String: Any] = [:]
            scriptletData["name"] = scriptlet.name
            scriptletData["args"] = scriptlet.args
            scriptlets.append(scriptletData)
        }

        payload["scriptlets"] = scriptlets

        return payload
    }

    private func createResponse(with json: [String: Any?]) -> NSExtensionItem {
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [ SFExtensionMessageKey: json ]
        } else {
            response.userInfo = [ "message": json ]
        }

        return response
    }

    private func getMessage(from request: NSExtensionItem?) -> [String: Any?]? {
        if request == nil {
            return nil
        }

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        if message is [String: Any?] {
            return message as? [String: Any?]
        }

        return nil
    }
}

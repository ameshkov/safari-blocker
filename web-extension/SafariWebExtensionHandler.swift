//
//  SafariWebExtensionHandler.swift
//  web-extension
//
//  Created by Andrey Meshkov on 17/12/2024.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    // private let blockerList: String

    override init() {
        // let blockerListFileURL = Bundle.main.url(forResource: "blockerList", withExtension: "txt")!
        // self.blockerList = try! String(contentsOf: blockerListFileURL, encoding: .utf8)

        super.init()
    }

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        var message = getMessage(from: request)

        if message == nil {
            context.completeRequest(returningItems: [])

            return
        }

        // let name = message?["name"] as? String
        if var timings = message?["timings"] as? [String: Int64] {
            timings["native"] = Int64(Date().timeIntervalSince1970 * 1000)
            message?["timings"] = timings // Reassign the modified dictionary back
        }

        message!["rules"] = "b".padding(toLength: 10000, withPad: "a", startingAt: 0)
        // let idx = blockerList.index(blockerList.startIndex, offsetBy: 10000)
        // message!["rules"] = blockerList[..<idx]

        let response = createResponse(with: message!)

        context.completeRequest(returningItems: [ response ], completionHandler: nil)
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

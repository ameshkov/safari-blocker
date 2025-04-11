//
//  WebExtensionRequestHandler.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 11/04/2025.
//

internal import FilterEngine
import SafariServices
import os.log

/// TODO(ameshkov): Write better comment
public enum WebExtensionRequestHandler {
    /// TODO(ameshkov): Write better comment
    public static func beginRequest(with context: NSExtensionContext) {
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
                do {
                    let webExtension = try WebExtension.shared(
                        groupID: GroupIdentifier.shared.value
                    )

                    var topUrl: URL?
                    if let topUrlString = payload["topUrl"] as? String {
                        topUrl = URL(string: topUrlString)
                    }

                    if let configuration = webExtension.lookup(pageUrl: url, topUrl: topUrl) {
                        message?["payload"] = convertToPayload(configuration)
                    }
                } catch {
                    os_log(
                        .error,
                        "Failed to get WebExtension instance: %@",
                        error.localizedDescription
                    )
                }
            }
        }

        if var trace = message?["trace"] as? [String: Int64] {
            trace["nativeStart"] = nativeStart
            trace["nativeEnd"] = Int64(Date().timeIntervalSince1970 * 1000)
            message?["trace"] = trace  // Reassign the modified dictionary back
        }

        // Enable verbose logging in the content script.
        // In the real app `verbose` flag should only be true for debugging purposes.
        message?["verbose"] = true

        if let safeMessage = message {
            let response = createResponse(with: safeMessage)
            context.completeRequest(returningItems: [response], completionHandler: nil)
        } else {
            context.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    private static func convertToPayload(
        _ configuration: WebExtension.Configuration
    ) -> [String: Any] {
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

    private static func createResponse(with json: [String: Any?]) -> NSExtensionItem {
        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [SFExtensionMessageKey: json]
        } else {
            response.userInfo = ["message": json]
        }

        return response
    }

    private static func getMessage(from request: NSExtensionItem?) -> [String: Any?]? {
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

        os_log(
            .default,
            "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)",
            String(describing: message),
            profile?.uuidString ?? "none"
        )

        if message is [String: Any?] {
            return message as? [String: Any?]
        }

        return nil
    }
}

//
//  ContentBlockerExtensionRequestHandler.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

/// Implements content blocker extension logic.
/// TODO(ameshkov): Write better comment
public enum ContentBlockerExtensionRequestHandler {
    /// Handles content blocking extension request for rules.
    public static func handleRequest(with context: NSExtensionContext, groupIdentifier: String) {
        NSLog("Start loading the content blocker")

        // Get the shared container URL.
        guard
            let appGroupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: groupIdentifier
            )
        else {
            context.cancelRequest(
                withError: createError(code: 1001, message: "Failed to access App Group container.")
            )
            return
        }

        let sharedFileURL = appGroupURL.appendingPathComponent(Constants.SAFARI_BLOCKER_FILE_NAME)

        var blockerListFileURL = sharedFileURL
        if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
            NSLog("No blocker list file found. Using the default one.")

            guard
                let defaultURL = Bundle.main.url(forResource: "blockerList", withExtension: "json")
            else {
                context.cancelRequest(
                    withError: createError(
                        code: 1002,
                        message: "Failed to find default blocker list."
                    )
                )
                return
            }
            blockerListFileURL = defaultURL
        }

        guard let attachment = NSItemProvider(contentsOf: blockerListFileURL) else {
            context.cancelRequest(
                withError: createError(code: 1003, message: "Failed to create attachment.")
            )
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(
            returningItems: [item]
        ) { _ in
            NSLog("Finished loading the content blocker")
        }
    }

    private static func createError(code: Int, message: String) -> NSError {
        return NSError(
            domain: "dev.adguard.safari-blocker",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

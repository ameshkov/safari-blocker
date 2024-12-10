//
//  ContentBlockerRequestHandler.swift
//  content-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        NSLog("Start loading the content blocker")
        
        // Get the shared container URL.
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "dev.adguard.safari-blocker.group") else {
            context.cancelRequest(withError: createError(code: 1001, message: "Failed to access App Group container."))
            return
        }
        
        let sharedFileURL = appGroupURL.appendingPathComponent("blockerList.json")
        
        var blockerListFileURL = sharedFileURL
        if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
            NSLog("No blocker list file found. Using the default one.")
            
            blockerListFileURL = Bundle.main.url(forResource: "blockerList", withExtension: "json")!
        }

        let attachment = NSItemProvider(contentsOf: blockerListFileURL)!
        
        let item = NSExtensionItem()
        item.attachments = [attachment]
        
        context.completeRequest(returningItems: [ item ],
                                completionHandler: { _ in
            NSLog("Finished loading the content blocker")
        })
    }
    
}

func createError(code: Int, message: String) -> NSError {
    return NSError(
        domain: "dev.adguard.safari-blocker",
        code: code,
        userInfo: [NSLocalizedDescriptionKey: message]
    )

}
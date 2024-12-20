//
//  ContentBlockerService.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import Foundation
internal import ContentBlockerConverter
import SafariServices

/// Runs the conversion logic and prepares the content blocker file.
public class ContentBlockerService {
    
    /// Reads the default filter file contents.
    public static func readDefaultFilterList() -> String {
        let filePath = Bundle.main.url(forResource: "filter", withExtension: "txt")
        do {
            return try String(contentsOf: filePath!, encoding: .utf8)
        }
        catch {
            return "Failed to read the filter file: \(error)"
        }
    }
    
    /// Reloads the content blocker.
    public static func reloadContentBlocker(withIdentifier identifier: String) -> Result<Void, Error> {
        NSLog("Start reloading the content blocker")
        
        let result = measure(label: "Reload safari") {
            reloadContentBlockerSynchronously(withIdentifier: identifier)
        }
        
        switch result {
        case .success:
            NSLog("Content blocker reloaded successfully.")
        case .failure(let error):
            //
            if error.localizedDescription.contains("WKErrorDomain error 6") {
                NSLog("Failed to reload content blocker due to access issue to the blocker list file: \(error.localizedDescription)")
            } else {                
                NSLog("Failed to reload content blocker: \(error.localizedDescription)")
            }
        }
        
        return result
    }
    
    /// Saves the passed JSON content to the content blocker file without attempting to convert them.
    ///
    /// - Returns: the number of entires in the JSON array.
    public static func saveContentBlocker(jsonRules: String, groupIdentifier: String) -> Int {
        NSLog("Saving content blocker rules")
        
        do {
            let jsonData = jsonRules.data(using: .utf8)!
            let rules = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
            
            measure(label: "Saving file") {
                saveBlockerListFile(contents: jsonRules, groupIdentifier: groupIdentifier)
            }
            
            return rules?.count ?? 0
        } catch {
            NSLog("Failed to decode JSON: \(error.localizedDescription)")
        }

        return 0
    }

    /// Converts AdGuard rules into the Safari content blocking rules syntax and returns
    /// the JSON contents.
    public static func convertRules(rules: String) -> (json: String, convertedCount: Int) {
        var filterRules = rules
        if !filterRules.isContiguousUTF8 {
            measure(label: "Make contigious UTF-8") {
                // This is super important for the conversion performance.
                // In a normal app make sure you're storing filter lists as
                // contigious UTF-8 strings.
                filterRules.makeContiguousUTF8()
            }
        }

        let lines = filterRules.components(separatedBy: "\n")

        let result = measure(label: "Conversion") {
            ContentBlockerConverter().convertArray(
                rules: lines,
                safariVersion: SafariVersion(18.1),
                optimize: false,
                advancedBlocking: true,
                advancedBlockingFormat: .txt,
                maxJsonSizeBytes: nil,
                progress: nil
            )
        }

        return (result.converted, result.convertedCount)
    }

    /// Converts filter.txt into the Safari content blocking rules syntax and saves to the content blocker file.
    /// This file will later be loaded by the content blocker extension.
    ///
    /// - Returns: the number of rules converted.
    public static func convertFilter(rules: String, groupIdentifier: String) -> Int {
        let result = convertRules(rules: rules)

        measure(label: "Saving file") {
            saveBlockerListFile(contents: result.json, groupIdentifier: groupIdentifier)
        }
        
        return result.convertedCount
    }
    
    /// Synchronous wrapper over SFContentBlockerManager.reloadContentBlocker.
    private static func reloadContentBlockerSynchronously(withIdentifier identifier: String) -> Result<Void, Error> {
        let semaphore = DispatchSemaphore(value: 0) // Create a semaphore with an initial count of 0
        var result: Result<Void, Error> = .success(())

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            semaphore.signal() // Signal the semaphore to unblock
        }
        
        semaphore.wait() // Block the thread until the semaphore is signaled
        return result
    }
    
    
    /// Saves the blocker list file contents to the shared directory.
    private static func saveBlockerListFile(contents: String, groupIdentifier: String) {
        // Get the shared container URL.
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            NSLog("Failed to access App Group container.")
            return
        }
        
        let sharedFileURL = appGroupURL.appendingPathComponent("blockerList.json")
        
        do {
            try contents.data(using: .utf8)?.write(to: sharedFileURL)
        } catch {
            NSLog("Failed to save blockerList.json: \(error.localizedDescription)")
        }
    }
    
}

func measure<T>(label: String, block: () -> T) -> T {
    let start = DispatchTime.now() // Start the timer
    
    let result = block() // Execute the code block
    
    let end = DispatchTime.now() // End the timer
    let elapsedNanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
    let elapsedMilliseconds = Double(elapsedNanoseconds) / 1_000_000 // Convert to milliseconds
    
    // Pretty print elapsed time
    let formattedTime = String(format: "%.3f", elapsedMilliseconds)
    NSLog("[\(label)] Elapsed Time: \(formattedTime) ms")
    
    return result
}

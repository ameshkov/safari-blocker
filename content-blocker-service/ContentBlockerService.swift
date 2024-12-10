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
    
    /// Converts filter.txt into the Safari content blocking rules syntax.
    ///
    /// - Returns: the number of rules converted.
    public static func convertFilter(rules: String) -> Int {
        let lines = rules.components(separatedBy: "\n")

        let result = measure(label: "Conversion") {
            ContentBlockerConverter().convertArray(
                rules: lines,
                safariVersion: .safari16_4Plus(18.1),
                optimize: false,
                advancedBlocking: true,
                advancedBlockingFormat: .txt,
                maxJsonSizeBytes: nil,
                progress: nil
            )
        }
        
        measure(label: "Saving file") {
            saveBlockerListFile(contents: result.converted)
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
    private static func saveBlockerListFile(contents: String) {
        // Get the shared container URL.
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.adguard.safari-blocker") else {
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
    
    /// Reads filtering rules from the embedded filter.txt file.
    private static func readRules() -> [String]? {
        let filePath = Bundle.main.url(forResource: "filter", withExtension: "txt")
        do {
            let rules = try String(contentsOf: filePath!, encoding: .utf8)
            let result = rules.components(separatedBy: "\n")
            NSLog("Loaded \(result.count) rules")
            
            return result
        }
        catch {
            NSLog("Error reading the filter file: \(error)")
        }
        
        return nil
    }
    
    /// Converts AdGuard filter rules into Safari content blocking syntax.
    private static func convertRules(rules: [String]) -> ConversionResult? {
        let result: ConversionResult? = ContentBlockerConverter().convertArray(rules: rules, advancedBlocking: true)
        
        return result!
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

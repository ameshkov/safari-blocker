//
//  ContentBlockerService.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import Foundation
import SafariServices
internal import ContentBlockerConverter
internal import ZIPFoundation

/// Runs the conversion logic and prepares the content blocker file.
public class ContentBlockerService {

    /// Reads the default filter file contents.
    ///
    /// - Returns: The default filter list contents.
    public static func readDefaultFilterList() -> String {
        let filePath = Bundle.main.url(forResource: "filter", withExtension: "txt")
        do {
            return try String(contentsOf: filePath!, encoding: .utf8)
        }
        catch {
            return "Failed to read the filter file: \(error)"
        }
    }

    /// Converts AdGuard rules and returns
    ///
    /// - Parameters:
    ///   - rules: AdGuard rules.
    /// - Returns: Safari rules JSON and advanced rules.
    public static func exportConversionResult(rules: String) -> Data? {
        let result = convertRules(rules: rules)

        let safariRulesJSON = result.safariRulesJSON
        let advancedRulesText = result.advancedRulesText

        return createZipArchive(safariRulesJSON: safariRulesJSON, advancedRulesText: advancedRulesText)
    }

    /// Reloads the content blocker.
    ///
    /// - Parameters:
    ///   - identifier: Bundle ID of the content blocker extension.
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
    /// - Parameters:
    ///   - jsonRules: Safari content blocker JSON contents.
    ///   - groupIdentifier: Group ID to use for the shared container where the file will be saved.
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

    /// Converts AdGuard rules into the Safari content blocking rules syntax and saves to the content blocker file.
    /// This file will later be loaded by the content blocker extension.
    ///
    /// - Parameters:
    ///   - rules: AdGuard rules to be converted.
    ///   - groupIdentifier: Group ID to use for the shared container where the file will be saved.
    /// - Returns: the number of rules converted.
    public static func convertFilter(rules: String, groupIdentifier: String) -> Int {
        let result = convertRules(rules: rules)

        measure(label: "Saving file") {
            saveBlockerListFile(contents: result.safariRulesJSON, groupIdentifier: groupIdentifier)
        }

        return result.safariRulesCount
    }

}

// MARK: - Private Helpers

extension ContentBlockerService {

    /// Converts AdGuard rules into the Safari content blocking rules syntax.
    ///
    /// - Parameters:
    ///   - rules: AdGuard rules to convert.
    private static func convertRules(rules: String) -> ConversionResult {
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
                advancedBlocking: true,
                maxJsonSizeBytes: nil,
                progress: nil
            )
        }

        return result
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

    /// Creates a ZIP archive with two files: "content-blocker.json" and "advanced-rules.txt".
    /// Returns Data of this file or nil if it fails to create a zip archive.
    private static func createZipArchive(safariRulesJSON: String,
                                         advancedRulesText: String?) -> Data? {
        // 1. Prepare data from strings
        let contentBlockerData = safariRulesJSON.data(using: .utf8)!
        let advancedData = advancedRulesText?.data(using: .utf8)

        do {
            // 3. Create the Archive object with ZipFoundation
            let archive = try Archive(accessMode: .create)

            // 4. Add content-blocker.json entry
            try archive.addEntry(
                with: "content-blocker.json",
                type: .file,
                uncompressedSize: Int64(contentBlockerData.count),
                bufferSize: 4,
                provider: { (position, size) -> Data in
                    // This will be called until `data` is exhausted (3x in this case).
                    return contentBlockerData.subdata(in: Data.Index(position)..<Int(position)+size)
                }
            )


            // 5. Add advanced-rules.txt if present
            if let advancedData = advancedData {
                try archive.addEntry(
                    with: "advanced-rules.txt",
                    type: .file,
                    uncompressedSize: Int64(advancedData.count),
                    bufferSize: 4,
                    provider: { (position, size) -> Data in
                        // This will be called until `data` is exhausted (3x in this case).
                        return advancedData.subdata(in: Data.Index(position)..<Int(position)+size)
                    }
                )
            }

            // 6. Zip creation complete
            return archive.data

        } catch {
            NSLog("Error while creating ZIP archive: \(error.localizedDescription)")
            return nil
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

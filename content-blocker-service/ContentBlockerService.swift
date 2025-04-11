//
//  ContentBlockerService.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

internal import ContentBlockerConverter
internal import FilterEngine
import Foundation
import SafariServices
internal import ZIPFoundation

/// Runs the conversion logic and prepares the content blocker file.
public enum ContentBlockerService {
    /// Reads the default filter file contents.
    ///
    /// - Returns: The default filter list contents.
    public static func readDefaultFilterList() -> String {
        do {
            if let filePath = Bundle.main.url(forResource: "filter", withExtension: "txt") {
                return try String(contentsOf: filePath, encoding: .utf8)
            }

            return "Not found the default filter file"
        } catch {
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

        // We'll use a variable so we can modify the JSON string
        var safariRulesJSON = result.safariRulesJSON
        let advancedRulesText = result.advancedRulesText

        // Attempt to pretty-print the JSON
        if let data = safariRulesJSON.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted]
            ),
            let prettyString = String(data: prettyData, encoding: .utf8)
        {
            safariRulesJSON = prettyString
        }

        // Pass the newly formatted JSON string to the ZIP creation
        return createZipArchive(
            safariRulesJSON: safariRulesJSON,
            advancedRulesText: advancedRulesText
        )
    }

    /// Reloads the content blocker.
    ///
    /// - Parameters:
    ///   - identifier: Bundle ID of the content blocker extension.
    public static func reloadContentBlocker(
        withIdentifier identifier: String
    ) -> Result<Void, Error> {
        NSLog("Start reloading the content blocker")

        let result = measure(label: "Reload safari") {
            reloadContentBlockerSynchronously(withIdentifier: identifier)
        }

        switch result {
        case .success:
            NSLog("Content blocker reloaded successfully.")
        case .failure(let error):
            // WKErrorDomain error 6 is a common error when the content blocker
            // cannot access the blocker list file.
            if error.localizedDescription.contains("WKErrorDomain error 6") {
                NSLog(
                    "Failed to reload content blocker due to access issue "
                        + "to the blocker list file: \(error.localizedDescription)"
                )
            } else {
                NSLog("Failed to reload content blocker: \(error.localizedDescription)")
            }
        }

        return result
    }

    /// Saves the passed JSON content to the content blocker file without
    /// attempting to convert them.
    ///
    /// - Parameters:
    ///   - jsonRules: Safari content blocker JSON contents.
    ///   - groupIdentifier: Group ID to use for the shared container where
    ///                      the file will be saved.
    /// - Returns: the number of entires in the JSON array.
    public static func saveContentBlocker(jsonRules: String, groupIdentifier: String) -> Int {
        NSLog("Saving content blocker rules")

        do {
            guard let jsonData = jsonRules.data(using: .utf8) else {
                // In theory, this cannot happen.
                fatalError("Failed to convert string to bytes")
            }
            let rules =
                try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]

            measure(label: "Saving file") {
                saveBlockerListFile(contents: jsonRules, groupIdentifier: groupIdentifier)
            }

            return rules?.count ?? 0
        } catch {
            NSLog("Failed to decode JSON: \(error.localizedDescription)")
        }

        return 0
    }

    /// Converts AdGuard rules into the Safari content blocking rules syntax and
    /// saves to the content blocker file.
    ///
    /// This file will later be loaded by the content blocker extension.
    ///
    /// - Parameters:
    ///   - rules: AdGuard rules to be converted.
    ///   - groupIdentifier: Group ID to use for the shared container where
    ///                      the file will be saved.
    /// - Returns: the number of rules converted.
    public static func convertFilter(rules: String, groupIdentifier: String) -> Int {
        let result = convertRules(rules: rules)

        measure(label: "Saving content blocking rules file") {
            saveBlockerListFile(contents: result.safariRulesJSON, groupIdentifier: groupIdentifier)
        }

        if let advancedRulesText = result.advancedRulesText {
            measure(label: "Building and saving engine") {
                do {
                    let webExtension = try WebExtension.shared(groupID: groupIdentifier)

                    // Build the engine and serialize it.
                    _ = try webExtension.buildFilterEngine(rules: advancedRulesText)
                } catch {
                    NSLog("Failed to build and save engine: \(error.localizedDescription)")
                }
            }
        }

        return result.safariRulesCount
    }
}

// MARK: - Safari Content Blocker functions

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
    private static func reloadContentBlockerSynchronously(
        withIdentifier identifier: String
    ) -> Result<Void, Error> {
        // Create a semaphore with an initial count of 0
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Void, Error> = .success(())

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            // Signal the semaphore to unblock
            semaphore.signal()
        }

        // Block the thread until the semaphore is signaled
        semaphore.wait()
        return result
    }

    /// Saves the blocker list file contents to the shared directory.
    private static func saveBlockerListFile(contents: String, groupIdentifier: String) {
        // Get the shared container URL.
        guard
            let appGroupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: groupIdentifier
            )
        else {
            NSLog("Failed to access App Group container.")
            return
        }

        let sharedFileURL = appGroupURL.appendingPathComponent(Constants.SAFARI_BLOCKER_FILE_NAME)

        do {
            try contents.data(using: .utf8)?.write(to: sharedFileURL)
        } catch {
            NSLog("Failed to save blockerList.json: \(error.localizedDescription)")
        }
    }

    /// Creates a ZIP archive with two files: "content-blocker.json" and "advanced-rules.txt".
    /// Returns Data of this file or nil if it fails to create a zip archive.
    private static func createZipArchive(
        safariRulesJSON: String,
        advancedRulesText: String?
    ) -> Data? {
        // 1. Prepare data from strings
        guard let contentBlockerData = safariRulesJSON.data(using: .utf8) else {
            // In theory, this cannot happen.
            fatalError("Failed to convert string to bytes")
        }
        let advancedData = advancedRulesText?.data(using: .utf8)

        do {
            // 3. Create the Archive object with ZipFoundation
            let archive = try Archive(accessMode: .create)

            // 4. Add content-blocker.json entry
            try archive.addEntry(
                with: "content-blocker.json",
                type: .file,
                uncompressedSize: Int64(contentBlockerData.count),
                bufferSize: 4
            ) { position, size -> Data in
                // This will be called until `data` is exhausted (3x in this case).
                return contentBlockerData.subdata(
                    in: Data.Index(position)..<Int(position) + size
                )
            }

            // 5. Add advanced-rules.txt if present
            if let advancedData = advancedData {
                try archive.addEntry(
                    with: "advanced-rules.txt",
                    type: .file,
                    uncompressedSize: Int64(advancedData.count),
                    bufferSize: 4
                ) { position, size -> Data in
                    // This will be called until `data` is exhausted (3x in this case).
                    return advancedData.subdata(in: Data.Index(position)..<Int(position) + size)
                }
            }

            // 6. Zip creation complete
            return archive.data
        } catch {
            NSLog("Error while creating ZIP archive: \(error.localizedDescription)")
            return nil
        }
    }
}

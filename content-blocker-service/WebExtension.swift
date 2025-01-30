//
//  WebExtension.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 29/01/2025.
//
internal import FilterEngine
internal import ContentBlockerConverter

/// WebExtension is responsible for working with `FilterEngine`.
public class WebExtension {

    /// Represents scriptlet data: its name and arguments.
    public struct Scriptlet {
        public let name: String
        public let args: [String]
    }

    /// Represents content script configuration that needs to be applied.
    public struct Configuration {
        public let css: [String]
        public let extendedCss: [String]
        public let js: [String]
        public let scriptlets: [Scriptlet]
    }

    private let groupIdentifier: String
    private let userDefaults: UserDefaults
    private var filterEngine: FilterEngine? = nil
    private var engineTimestamp: Double = 0

    /// Initializes an instance of `WebExtension`.
    ///
    /// - Parameters:
    ///   - groupIdentifier: Group ID to get access to shared files with the `FilterEngine` data.
    public init(groupIdentifier: String) {
        self.groupIdentifier = groupIdentifier
        self.userDefaults = UserDefaults(suiteName: groupIdentifier)!
    }

    /// Looks up filtering rules in the filtering engine.
    ///
    /// - Parameters:
    ///   - url: URL of the page where the rules should be applied.
    /// - Returns: the list of rules to be applied.
    public func lookup(for url: URL) -> Configuration? {
        guard let engine = getFilterEngine() else {
            return nil
        }

        let rules = engine.findAll(for: url)

        return createConfiguration(rules)
    }
}

// MARK: - Creating ContentScript configuration

extension WebExtension {

    /// Creates content script configuration object with the rules that need to be applied on the page.
    private func createConfiguration(_ rules: [FilterRule]) -> Configuration {
        var css: [String] = []
        var extendedCss: [String] = []
        var js: [String] = []
        var scriptlets: [Scriptlet] = []

        for rule in rules {
            guard let cosmeticContent = rule.cosmeticContent else {
                continue
            }

            if rule.action.contains(.cssDisplayNone) ||
                rule.action.contains(.cssInject) {

                if rule.action.contains(.extendedCSS) {
                    extendedCss.append(cosmeticContent)
                } else {
                    css.append(cosmeticContent)
                }
            } else if rule.action == .scriptInject {
                js.append(cosmeticContent)
            } else if rule.action == .scriptlet {
                if let data = try? ScriptletParser.parse(data: cosmeticContent) {
                    scriptlets.append(Scriptlet(name: data.name, args: []))
                }
            }
        }

        return Configuration(
            css: css,
            extendedCss: extendedCss,
            js: js,
            scriptlets: scriptlets
        )
    }
}

// MARK: - Filter Engine lazy initialization

extension WebExtension {

    /// Gets or creates `FilterEngine`.
    private func getFilterEngine() -> FilterEngine? {
        let engineTimestamp = userDefaults.double(forKey: Constants.ENGINE_TIMESTAMP_KEY)
        if engineTimestamp == 0 {
            // Engine was never initialized.
            return nil
        }

        if engineTimestamp > self.engineTimestamp {
            // Init the engine and save to the private field.
            measure(label: "Initialize FilterEngine") {
                let filterEngine = createFilterEngine()

                self.filterEngine = filterEngine
                self.engineTimestamp = engineTimestamp
            }
        }

        // Return the engine.
        return filterEngine
    }

    /// Creates a new instance of FilterEngine by deserializing data from the shared files.
    private func createFilterEngine() -> FilterEngine? {
        // Get the shared container URL.
        guard let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            NSLog("Failed to access App Group container.")
            return nil
        }

        let filterRuleStorageURL = appGroupURL.appendingPathComponent(Constants.FILTER_RULE_STORAGE_FILE_NAME)
        let filterEngineIndexURL = appGroupURL.appendingPathComponent(Constants.FILTER_ENGINE_INDEX_FILE_NAME)

        // Check if the relevant files exist, otherwise bail out
        guard FileManager.default.fileExists(atPath: filterRuleStorageURL.path),
              FileManager.default.fileExists(atPath: filterEngineIndexURL.path) else {
            NSLog("Filter engine files do not exist.")
            return nil
        }

        // Deserialize the FilterRuleStorage.
        guard let storage = try? FilterRuleStorage(fileURL: filterRuleStorageURL) else {
            NSLog("Failed to deserialize the storage.")
            return nil
        }

        // Deserialize the engine.
        guard let engine = try? FilterEngine(storage: storage, indexFileURL: filterEngineIndexURL) else {
            NSLog("Failed to deserialize the engine.")
            return nil
        }

        return engine
    }

    // TODO(ameshkov): !!! Implement properly
    private func encodeFilterRule(_ rule: FilterRule) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(rule)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

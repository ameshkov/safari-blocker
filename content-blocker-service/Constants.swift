//
//  Constants.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 29/01/2025.
//

class Constants {
    /// File name for the JSON file with Safari rules.
    static let SAFARI_BLOCKER_FILE_NAME = "blockerList.json"

    /// File name for the file with advanced filter rules storage.
    static let FILTER_RULE_STORAGE_FILE_NAME = "filterRulesStorage.bin"

    /// File name for the file with the serialized `FilterEngine` index.
    static let FILTER_ENGINE_INDEX_FILE_NAME = "filterEngineIndex.bin"

    /// Key to use in UserDefaults to save timestamp of when the engine was last time modified.
    static let ENGINE_TIMESTAMP_KEY = "engineTimestamp"
}

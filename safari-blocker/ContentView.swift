//
//  ContentView.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import SwiftUI
import Combine
import content_blocker_service

let CONTENT_BLOCKER_ID = "dev.adguard.safari-blocker.content-blocker"

let GROUP_ID: String = {
    let teamIdentifierPrefix: String = Bundle.main.infoDictionary?["AppIdentifierPrefix"]! as! String
    return "\(teamIdentifierPrefix)group.dev.adguard.safari-blocker"
}()

enum RuleType: String, CaseIterable, Identifiable {
    case adGuardFiltering = "AdGuard filtering rules"
    case adGuardFilterListsURLs = "AdGuard filter lists URLs"
    case safariContentBlocker = "Safari content blocker rules"
    case safariContentBlockerURL = "Safari content blocker URL"

    var id: String { self.rawValue }
}

struct ContentView: View {
    @State private var isLoading: Bool = true
    @State private var statusDescription: String = ""
    @State private var elapsedConversion: String = "5.32s"
    @State private var elapsedLoad: String = "1.25s"
    @State private var error: Bool = false
    @State private var userInput: String
    @State private var selectedRuleType: RuleType = .adGuardFiltering

    var editorLabel: String {
        switch selectedRuleType {
        case .adGuardFiltering:
            return "Enter AdGuard filtering rules"
        case .safariContentBlockerURL:
            return "Enter Safari content blocker JSON URL"
        case .adGuardFilterListsURLs:
            return "Enter filter list URLs (one per line)"
        case .safariContentBlocker:
            return "Enter rules for Safari content blocker"
        }
    }

    init() {
        userInput = ContentBlockerService.readDefaultFilterList()
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text(statusDescription)
                    .padding(.top, 10)
            }

            if !isLoading {
                HStack {
                    Image("AppIconImage")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    Text("Safari Content Blocker")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Status: \(statusDescription)")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(error ? Color.red : Color.primary)
                    
                    Spacer()
                }.padding(.bottom, 5)

                HStack {
                    Picker("Select Rule Type", selection: $selectedRuleType) {
                        ForEach(RuleType.allCases) { ruleType in
                            Text(ruleType.rawValue).tag(ruleType)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())

                    Spacer()
                }.padding(.bottom, 5)

                HStack {
                    Text(editorLabel)
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                    
                    Spacer()
                }

                TextEditor(text: $userInput)
                    .font(.body)
                    .background(Color.white)
                    .border(Color.gray, width: 1)
                    .autocorrectionDisabled(true)
                
                Spacer()
                
                HStack {
                    Button(action: prepareContentBlocker) {
                        Text("Reload filter")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("s", modifiers: .command)

                    if selectedRuleType == .adGuardFiltering || selectedRuleType == .adGuardFilterListsURLs {
                        Button(action: exportContentBlocker) {
                            Text("Export content blocker...")
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
                
                HStack {
                    Text("Elapsed on conversion: \(elapsedConversion)")
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }.padding(.top, 5)
                
                HStack {
                    Text("Elapsed on loading into Safari: \(elapsedLoad)")
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("You need to enable Safari Extension now. It may be required to enable unsigned extensions in Safari Developer options")
                        .font(.footnote)
                    Spacer()
                }.padding(.top, 5)
            }
        }
        .frame(minWidth: 400, idealWidth: 400, minHeight: 300, idealHeight: 400)
        .padding()
        .onAppear {
            prepareContentBlocker()
        }
    }

    private func getContent() -> String? {
        let inputContent = userInput.trimmingCharacters(in: .whitespacesAndNewlines)

        switch selectedRuleType {
        case .adGuardFiltering:
            return inputContent
        case .adGuardFilterListsURLs:
            let urls = inputContent.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            var concatenatedContent = ""
            for urlString in urls {
                guard let url = URL(string: urlString) else {
                    return nil
                }
                let content = try? downloadContent(from: url)
                if content == nil {
                    return nil
                }

                concatenatedContent.append(content!)
                concatenatedContent.append("\n")
            }

            return concatenatedContent

        case .safariContentBlocker:
            return inputContent
        case .safariContentBlockerURL:
            guard let url = URL(string: inputContent) else {
                return nil
            }

            return try? downloadContent(from: url)
        }
    }

    private func downloadContent(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)

        return String(data: data, encoding: .utf8)!
    }

    private func exportContentBlocker() {
        DispatchQueue.global().async {
            self.isLoading = true
            self.statusDescription = "Converting content blocking rules"
            var elapsedConversion = "5.23s"
            var convertedCount = 0

            if ProcessInfo.processInfo.isRunningInPreview {
                Thread.sleep(forTimeInterval: 1)
            } else {
                let start = Date()

                let content = getContent() ?? ""
                let conversionResult = ContentBlockerService.convertRules(rules: content)

                convertedCount = conversionResult.convertedCount

                let endConversion = Date()
                elapsedConversion = String(format: "%.2fs", endConversion.timeIntervalSince(start))

                DispatchQueue.main.async {
                    let savePanel = NSSavePanel()
                    savePanel.nameFieldStringValue = "content-blocker"
                    savePanel.allowedContentTypes = [.json]

                    savePanel.begin { result in
                        if result == .OK, let url = savePanel.url {
                            do {
                                try conversionResult.json.write(to: url, atomically: true, encoding: .utf8)
                                print("File saved to \(url)")
                            } catch {
                                print("Error saving file: \(error)")
                            }
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.isLoading = false
                self.elapsedConversion = elapsedConversion
                self.elapsedLoad = "0s"
                self.statusDescription = "Exported \(convertedCount) rules"
            }
        }
    }

    private func prepareContentBlocker() {
        self.isLoading = true
        self.statusDescription = "Converting content blocking rules"
        
        DispatchQueue.global().async {
            var elapsedConversion = "5.23s"
            var elapsedLoad = "1.52s"
            var convertedCount = 5
            var result: Result<Void, Error> = .success(())
            
            if ProcessInfo.processInfo.isRunningInPreview {
                Thread.sleep(forTimeInterval: 1)
            } else {
                let start = Date()
                
                let content = getContent() ?? ""
                let json = selectedRuleType == .safariContentBlocker || selectedRuleType == .safariContentBlockerURL

                if json {
                    convertedCount = ContentBlockerService.saveContentBlocker(jsonRules: content, groupIdentifier: GROUP_ID)
                } else {
                    convertedCount = ContentBlockerService.convertFilter(rules: content, groupIdentifier: GROUP_ID)
                }
                
                let endConversion = Date()
                elapsedConversion = String(format: "%.2fs", endConversion.timeIntervalSince(start))
                
                DispatchQueue.main.async {
                    self.statusDescription = "Loading content blocker to Safari"
                }

                result = ContentBlockerService.reloadContentBlocker(withIdentifier: CONTENT_BLOCKER_ID)
                
                let endLoad = Date()
                elapsedLoad = String(format: "%.2fs", endLoad.timeIntervalSince(endConversion))
            }

            DispatchQueue.main.async {
                self.isLoading = false
                self.elapsedConversion = elapsedConversion
                self.elapsedLoad = elapsedLoad
                
                switch result {
                case .success:
                    self.statusDescription = "Loaded \(convertedCount) \(convertedCount == 1 ? "rule" : "rules") to Safari"
                    self.error = false
                case .failure(let error):
                    self.statusDescription = "Failed to load rules due to \(error.localizedDescription)"
                    self.error = true
                }
            }
        }
    }
}

// Extension to check if running in Preview
extension ProcessInfo {
    var isRunningInPreview: Bool {
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview {
    ContentView()
}

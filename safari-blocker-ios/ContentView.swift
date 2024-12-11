//
//  ContentView.swift
//  safari-blocker-ios
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import SwiftUI
import content_blocker_service

let CONTENT_BLOCKER_ID = "dev.adguard.safari-blocker-ios.content-blocker-ios"
let GROUP_ID = "group.dev.adguard.safari-blocker"


struct ContentView: View {
    @State private var isLoading: Bool = true
    @State private var statusDescription: String = ""
    @State private var elapsedConversion: String = "5.32s"
    @State private var elapsedLoad: String = "1.25s"
    @State private var error: Bool = false
    @State private var userInput: String
    
    init() {
        userInput = ContentBlockerService.readDefaultFilterList()
    }
    
    var body: some View {
        VStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text(statusDescription)
                        .padding(.top, 10)
                }
            }
            
            if !isLoading {
                ScrollView {
                    VStack(alignment:.leading) {
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
                            Text("Enter rules for Safari. Accepts both AdGuard rules and Safari content blocking JSON")
                                .multilineTextAlignment(.leading)
                                .font(.caption)
                            
                            Spacer()
                        }
                        
                        TextEditor(text: $userInput)
                            .font(.body)
                            .background(Color.white)
                            .border(Color.gray, width: 1)
                            .autocorrectionDisabled(true)
                            .frame(height:250)
                        
                        HStack {
                            let txt = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if txt.hasPrefix("[") &&
                                txt.hasSuffix("]") &&
                                txt.contains("{") {
                                Text("JSON detected, the rules will not be converted")
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text("AdGuard rules detected, the rules will be converted to Safari syntax")
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Button(action: prepareContentBlocker) {
                                Text("Reload filter")
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut("s", modifiers: .command)
                            
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
                            Text("You need to enable Safari Extension now")
                                .font(.footnote)
                            Spacer()
                        }.padding(.top, 5)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            prepareContentBlocker()
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
                
                let content = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let json = content.hasPrefix("[") && content.hasSuffix("]") &&
                content.contains("{")
                
                if json {
                    convertedCount = ContentBlockerService.saveContentBlocker(jsonRules: content, groupIdentifier: GROUP_ID)
                } else {
                    convertedCount = ContentBlockerService.convertFilter(rules: userInput, groupIdentifier: GROUP_ID)
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

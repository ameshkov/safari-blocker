//
//  ContentView.swift
//  safari-blocker-ios
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import SwiftUI
import content_blocker_service

struct ContentView: View {
    @State private var isLoading: Bool = true
    @State private var statusDescription: String = ""
    @State private var elapsedConversion: String = "5.32s"
    @State private var elapsedLoad: String = "1.25s"
    @State private var userInput: String
    
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
            } else {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text(statusDescription)
                        .padding(.top, 10)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Elapsed on conversion: \(elapsedConversion)")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    Text("Elapsed on loading into Safari: \(elapsedLoad)")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                    
                    Text("Enter user rules")
                        .font(.caption)
                        .padding(.top, 10)

                    TextEditor(text: $userInput)
                        .font(.body)
                        .background(Color.white)
                        .frame(height: 200)
                        .border(Color.gray, width: 1)
                    
                    Button(action: prepareContentBlocker) {
                        Text("Reload filter")
                    }
                    .padding(.top, 10)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("s", modifiers: .command)
                    
                    Text("You need to enable Safari Extension now. It may be required to enable unsigned extensions in Safari Developer options.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .padding(.top, 10)
                }
            }
        }
        .padding()
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
                
                convertedCount = ContentBlockerService.convertFilter(rules: userInput)
                
                let endConversion = Date()
                elapsedConversion = String(format: "%.2fs", endConversion.timeIntervalSince(start))
                
                DispatchQueue.main.async {
                    self.statusDescription = "Loading content blocker to Safari"
                }
                
                let identifier = "dev.adguard.safari-blocker.content-blocker"
                result = ContentBlockerService.reloadContentBlocker(withIdentifier: identifier)
                
                let endLoad = Date()
                elapsedLoad = String(format: "%.2fs", endLoad.timeIntervalSince(endConversion))
            }
            DispatchQueue.main.async {
                self.isLoading = false
                self.elapsedConversion = elapsedConversion
                self.elapsedLoad = elapsedLoad
                
                switch result {
                case .success:
                    self.statusDescription = "Loaded \(convertedCount) rules to Safari"
                case .failure(let error):
                    self.statusDescription = "Failed to load rules due to \(error.localizedDescription)"
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

//
//  ContentView.swift
//  safari-blocker
//
//  Created by Andrey Meshkov on 10/12/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading: Bool = true
    @State private var statusDescription: String = ""
    @State private var elapsedConversion: String = "5.32s"
    @State private var elapsedLoad: String = "1.25s"
    
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
                    Text("The content blocker has been loaded")
                        .padding(.top, 10)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("Elapsed on conversion: \(elapsedConversion)")
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                    Text("Elapsed on loading into Safari: \(elapsedLoad)")
                        .multilineTextAlignment(.center)

                    Button(action: prepareContentBlocker) {
                        Text("Reload filter")
                    }
                        .padding(.top, 10)
                        .buttonStyle(.borderedProminent)

                        
                    Text("You need to enable Safari Extension now")
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .italic()
                    Text("It may be required to enable unsigned extensions in Safari Developer options")
                        .multilineTextAlignment(.center)
                        .italic()
                    
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 400, minHeight: 300, idealHeight: 400)
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
            
            if ProcessInfo.processInfo.isRunningInPreview {
                Thread.sleep(forTimeInterval: 1)
            } else {
                let start = Date()
                
                ContentBlockerService.convertFilter()
                
                let endConversion = Date()
                elapsedConversion = String(format: "%.2fs", endConversion.timeIntervalSince(start))
                
                DispatchQueue.main.async {
                    self.statusDescription = "Loading content blocker to Safari"
                }

                ContentBlockerService.reloadContentBlocker()
                
                let endLoad = Date()
                elapsedLoad = String(format: "%.2fs", endLoad.timeIntervalSince(endConversion))
            }
            DispatchQueue.main.async {
                self.isLoading = false
                self.elapsedConversion = elapsedConversion
                self.elapsedLoad = elapsedLoad
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

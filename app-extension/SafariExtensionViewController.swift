//
//  SafariExtensionViewController.swift
//  app-extension
//
//  Created by Andrey Meshkov on 31/01/2025.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {

    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 320, height: 240)
        return shared
    }()

}

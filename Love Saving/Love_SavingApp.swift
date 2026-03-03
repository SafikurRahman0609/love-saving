//
//  Love_SavingApp.swift
//  Love Saving
//
//  Created by Safikur Rahman on 2/24/26.
//

import SwiftUI
import FirebaseCore

@main
struct Love_SavingApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()   
        }
    }
}

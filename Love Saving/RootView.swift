//
//  RootView.swift
//  Love Saving
//
//  Created by Safikur Rahman on 2/27/26.
//


import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var user: User? = Auth.auth().currentUser

    var body: some View {
        Group {
            if user == nil {
                AuthView(onAuthed: { user = Auth.auth().currentUser })
            } else {
                HomeDemoView(onSignOut: {
                    user = nil
                })
            }
        }
    }
}
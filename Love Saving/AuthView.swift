//
//  AuthView.swift
//  Love Saving
//
//  Created by Safikur Rahman on 2/27/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    var onAuthed: () -> Void

    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = "User"
    @State private var errorText: String?

    var body: some View {
        Form {
            Section(header: Text(isSignUp ? "Sign Up" : "Sign In")) {
                if isSignUp {
                    TextField("Display Name", text: $displayName)
                }
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
            }

            if let errorText {
                Text(errorText).foregroundStyle(.red)
            }

            Button(isSignUp ? "Create Account" : "Sign In") {
                Task { await submit() }
            }

            Button(isSignUp ? "Have an account? Sign In" : "No account? Sign Up") {
                isSignUp.toggle()
                errorText = nil
            }
        }
    }

    private func submit() async {
        errorText = nil
        do {
            if isSignUp {
                let res = try await Auth.auth().createUser(withEmail: email, password: password)
                let uid = res.user.uid
                let now = Date()

                // Create user doc in Firestore
                try await Firestore.firestore().collection("users").document(uid).setData([
                    "displayName": displayName,
                    "email": email,
                    "createdAt": now,
                    "updatedAt": now
                ], merge: true)

            } else {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
            }

            onAuthed()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

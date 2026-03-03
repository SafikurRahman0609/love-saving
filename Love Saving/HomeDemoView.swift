//
//  HomeDemoView.swift
//
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeDemoView: View {
    var onSignOut: () -> Void

    @State private var groupId: String?
    @State private var loveBalance: Int = 0
    @State private var statusText: String?
    @State private var groupListener: ListenerRegistration?   // 🔥 FIXED

    var body: some View {
        VStack(spacing: 14) {

            Text("Love Saving")
                .font(.title)

            Text("Email: \(Auth.auth().currentUser?.email ?? "")")
                .font(.footnote)

            if let gid = groupId {

                VStack(spacing: 4) {
                    Text("❤️ Your Love Group")
                        .font(.headline)

                    Text("ID: \(gid)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                .textSelection(.enabled)

                Text("Love Balance")
                    .font(.headline)

                Text("\(loveBalance)")
                    .font(.system(size: 56, weight: .bold))

                HStack {
                    Button("Deposit +1") {
                        Task { await addEvent(type: "deposit", delta: 1) }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Withdraw -1") {
                        Task { await addEvent(type: "withdraw", delta: -1) }
                    }
                    .buttonStyle(.bordered)
                }

            } else {

                Text("No group yet.")

                Button("Create Demo Group") {
                    Task { await createGroup() }
                }
                .buttonStyle(.borderedProminent)
            }

            if let statusText {
                Text(statusText)
                    .font(.footnote)
            }

            Button("Sign Out") {
                try? Auth.auth().signOut()
                onSignOut()
            }
            .foregroundStyle(.red)

            Spacer()
        }
        .padding()
        .onAppear {
            Task { await loadGroupFromUserDoc() }
        }
        .onDisappear {
            groupListener?.remove()
            groupListener = nil
        }
    }

    // MARK: - Load Existing Group

    private func loadGroupFromUserDoc() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snap = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            if let gid = snap.data()?["currentGroupId"] as? String,
               !gid.isEmpty {
                groupId = gid
                listenToGroup(gid)
            }

        } catch {
            statusText = "Load failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Create Group

    private func createGroup() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let now = Date()
        let groupRef = db.collection("groups").document()

        do {
            try await groupRef.setData([
                "groupName": "Demo Group",
                "memberIds": [uid],
                "createdBy": uid,
                "status": "active",
                "loveBalance": 0,
                "lastEventAt": now,
                "createdAt": now,
                "updatedAt": now
            ])

            try await db.collection("users")
                .document(uid)
                .setData([
                    "currentGroupId": groupRef.documentID,
                    "updatedAt": now
                ], merge: true)

            groupId = groupRef.documentID
            listenToGroup(groupRef.documentID)
            statusText = "Group created ✅"

        } catch {
            statusText = "Create group failed: \(error.localizedDescription)"
        }
    }

    // MARK: - LISTENER (🔥 FIXED)

    private func listenToGroup(_ gid: String) {

        // Remove old listener if exists
        groupListener?.remove()
        groupListener = nil

        groupListener = Firestore.firestore()
            .collection("groups")
            .document(gid)
            .addSnapshotListener { snap, error in

                if let error = error {
                    statusText = "Listen failed: \(error.localizedDescription)"
                    return
                }

                self.loveBalance = snap?.data()?["loveBalance"] as? Int ?? 0
            }
    }

    // MARK: - Add Event (Transaction)

    private func addEvent(type: String, delta: Int) async {
        guard let uid = Auth.auth().currentUser?.uid,
              let gid = groupId else { return }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(gid)
        let eventRef = groupRef.collection("events").document()
        let now = Date()

        do {
            try await db.runTransaction { txn, errPtr in

                let groupSnap: DocumentSnapshot
                do {
                    groupSnap = try txn.getDocument(groupRef)
                } catch {
                    errPtr?.pointee = error as NSError
                    return nil
                }

                let current = groupSnap.data()?["loveBalance"] as? Int ?? 0
                let newBalance = current + delta

                // Create event
                txn.setData([
                    "createdBy": uid,
                    "type": type,
                    "tapCount": 1,
                    "delta": delta,
                    "note": "Sprint 1 demo",
                    "occurredAt": now,
                    "location": ["lat": 0.0, "lng": 0.0],
                    "createdAt": now,
                    "updatedAt": now
                ], forDocument: eventRef)

                // Update balance
                txn.updateData([
                    "loveBalance": newBalance,
                    "lastEventAt": now,
                    "updatedAt": now
                ], forDocument: groupRef)

                return nil
            }

            statusText = "Event saved ✅"

        } catch {
            statusText = "Event failed: \(error.localizedDescription)"
        }
    }
}

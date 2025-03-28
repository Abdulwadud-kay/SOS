//
//  RecentsPage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/26/25.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct RecentsPage: View {
    @State private var closedCases: [Case] = []
    @State private var listenerRegistration: ListenerRegistration? = nil
    @State private var selectedCaseID: String? = nil
    
    var body: some View {
        NavigationStack {
            List(closedCases) { c in
                Button {
                    selectedCaseID = c.id
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(c.patientName)
                            .font(.headline)
                        
                        if let preview = c.chatHistory.first, !preview.isEmpty {
                            Text("🗨️ \(preview)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }

                        Text(displayDate(c.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Status: \(c.status)")
                            .font(.caption)
                            .foregroundColor(c.status == "Closed" ? .red : .gray)
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.white)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Past Diagnoses")
            .onAppear { fetchRecents() }
            .onDisappear { listenerRegistration?.remove() }
            .navigationDestination(for: String.self) { caseID in
                HomePage(incomingCaseID: caseID)
            }
        }
    }

    func fetchRecents() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases")
            .whereField("patientUid", isEqualTo: user.uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snap, err in
                if let err = err {
                    print("Error fetching recents: \(err)")
                    return
                }
                guard let docs = snap?.documents else {
                    closedCases = []
                    return
                }

                closedCases = docs.map { doc in
                    let d = doc.data()
                    let chat = d["chatHistory"] as? [String] ?? []

                    // Grab the most recent GPT/User message
                    let lastMsg = chat.reversed().first(where: {
                        $0.hasPrefix("GPT:") || $0.hasPrefix("User:")
                    }) ?? ""

                    let preview = lastMsg
                        .replacingOccurrences(of: "GPT:", with: "")
                        .replacingOccurrences(of: "User:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    return Case(
                        id: doc.documentID,
                        patientName: d["patientName"] as? String ?? "Unknown",
                        age: d["age"] as? Int ?? 0,
                        medicalHistory: d["medicalHistory"] as? String ?? "",
                        chatHistory: [preview], // store only preview here
                        status: d["status"] as? String ?? "Closed",
                        createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
    }

    func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RecentsPage_Previews: PreviewProvider {
    static var previews: some View {
        RecentsPage()
    }
}

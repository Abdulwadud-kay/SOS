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
                    VStack(alignment: .leading) {
                        Text(c.patientName)
                            .font(.headline)
                        Text(displayDate(c.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if c.status == "Closed" || c.status == "Resolved" {
                            Text("Status: Closed")
                                .foregroundColor(.red)
                        } else {
                            Text("Status: \(c.status)")
                        }
                    }
                }
            }
            .navigationTitle("Recents")
            .onAppear {
                fetchRecents()
            }
            .onDisappear {
                listenerRegistration?.remove()
            }
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
                    return Case(
                        id: doc.documentID,
                        patientName: d["patientName"] as? String ?? "Unknown",
                        age: d["age"] as? Int ?? 0,
                        medicalHistory: d["medicalHistory"] as? String ?? "",
                        chatHistory: d["chatHistory"] as? [String] ?? [],
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

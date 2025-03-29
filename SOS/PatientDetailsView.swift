//
//  PatientDetailsView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/21/25.
//

import SwiftUI
import Firebase

struct PatientDetailsView: View {
    let caseID: String
    let onBack: () -> Void

    @State private var loadedCase: Case? = nil
    @State private var listenerRegistration: ListenerRegistration? = nil
    @State private var showChatHistory = false

    var body: some View {
        ScrollView {
            if let c = loadedCase {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button("Release Case") {
                            releaseCase(c.id)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    infoCard(title: "Patient Information") {
                        Text("Name: \(c.patientName)")
                        Text("Age: \(c.age)")
                    }

                    infoCard(title: "Medical History") {
                        if c.medicalHistory.isEmpty {
                            Text("No history provided").foregroundColor(.gray)
                        } else {
                            ForEach(c.medicalHistory.components(separatedBy: "\n"), id: \.self) { line in
                                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Text(line)
                                }
                            }
                        }
                    }

                    Button {
                        showChatHistory = true
                    } label: {
                        HStack {
                            Text("View Chat History")
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                    }
                    .padding(.top, 4)

                    HStack(spacing: 24) {
                        ForEach(["message", "phone", "video"], id: \.self) { icon in
                            Button {} label: {
                                Image(systemName: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 3, height: 25)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                Text("Loading patient data...")
                    .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Patient File")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .sheet(isPresented: $showChatHistory) {
            if let c = loadedCase {
                ChatHistoryView(caseID: c.id)
            } else {
                Text("No chat available.")
            }
        }
        .onAppear(perform: listenToCaseDocument)
        .onDisappear { listenerRegistration?.remove() }
    }

    func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Divider()
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    func listenToCaseDocument() {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases").document(caseID)
            .addSnapshotListener { snap, error in
                if let e = error {
                    print("Error fetching case: \(e)")
                    return
                }
                guard let data = snap?.data() else { return }
                loadedCase = Case(
                    id: caseID,
                    patientName: data["patientName"] as? String ?? "Unknown",
                    age: data["age"] as? Int ?? 0,
                    medicalHistory: data["medicalHistory"] as? String ?? "",
                    chatHistory: data["chatHistory"] as? [String] ?? [],
                    status: data["status"] as? String ?? "InProgress",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
    }

    func releaseCase(_ caseID: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseID).updateData([
            "status": "Pending",
            "professionalID": ""
        ]) { err in
            if let err = err {
                print("Error releasing case: \(err)")
            }
        }
    }
}

struct ChatHistoryView: View {
    let caseID: String
    @State private var chatMessages: [String] = []
    @State private var listenerRegistration: ListenerRegistration? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chatMessages, id: \.self) { msg in
                        if msg.hasPrefix("User:") {
                            HStack {
                                Spacer()
                                Text(msg.replacingOccurrences(of: "User:", with: ""))
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        } else if msg.hasPrefix("GPT:") {
                            HStack {
                                Text(msg.replacingOccurrences(of: "GPT:", with: ""))
                                    .padding()
                                    .foregroundColor(.primary)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Chat History", displayMode: .inline)
            .onAppear(perform: listenForChatUpdates)
            .onDisappear { listenerRegistration?.remove() }
        }
    }

    func listenForChatUpdates() {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases").document(caseID)
            .addSnapshotListener { snap, error in
                if let e = error {
                    print("Error listening for chat updates: \(e)")
                    return
                }
                guard let d = snap?.data() else { return }
                chatMessages = d["chatHistory"] as? [String] ?? []
            }
    }
}

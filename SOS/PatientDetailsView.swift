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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patient Information")
                            .font(.headline)
                        Divider()
                        Text("Name: \(c.patientName)")
                        Text("Age: \(c.age)")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical History")
                            .font(.headline)
                        Divider()
                        if c.medicalHistory.isEmpty {
                            Text("No history provided").foregroundColor(.gray)
                        } else {
                            Text(c.medicalHistory)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    Button(action: { showChatHistory = true }) {
                        HStack {
                            Text("View Chat History")
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 24) {
                        Button(action: {}) {
                            Image(systemName: "message.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.blue)
                        }
                        Button(action: {}) {
                            Image(systemName: "phone.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.blue)
                        }
                        Button(action: {}) {
                            Image(systemName: "video.fill")
                                .resizable()
                                .frame(width: 40, height: 30)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            } else {
                Text("Loading patient data...")
                    .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Patient File")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onBack()
                } label: {
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
        .onAppear {
            listenToCaseDocument()
        }
        .onDisappear {
            listenerRegistration?.remove()
        }
    }
    
    func listenToCaseDocument() {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases").document(caseID)
            .addSnapshotListener { snap, error in
                if let e = error {
                    print("Error fetching case: \(e)")
                    return
                }
                guard let data = snap?.data() else {
                    print("No case data found.")
                    return
                }
                let newCase = Case(
                    id: caseID,
                    patientName: data["patientName"] as? String ?? "Unknown",
                    age: data["age"] as? Int ?? 0,
                    medicalHistory: data["medicalHistory"] as? String ?? "",
                    chatHistory: data["chatHistory"] as? [String] ?? [],
                    status: data["status"] as? String ?? "InProgress"
                )
                loadedCase = newCase
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
                                    .foregroundColor(.black)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                Spacer()
                            }
                        } else {
                            Text(msg)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Chat History", displayMode: .inline)
            .onAppear {
                listenForChatUpdates()
            }
            .onDisappear {
                listenerRegistration?.remove()
            }
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
                if let history = d["chatHistory"] as? [String] {
                    chatMessages = history
                }
            }
    }
}

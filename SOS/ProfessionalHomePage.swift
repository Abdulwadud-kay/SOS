//
//  ProfessionalHomePage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/17/25.
//

import Foundation
import SwiftUI
import Firebase
import UserNotifications

struct ProfessionalHomePage: View {
    @State private var cases: [Case] = []
    @State private var selectedCase: Case? = nil
    @State private var showNotification = false
    @State private var notificationMessage = ""
    @State private var showProfileMenu = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                        Menu {
                        Button("Profile", action: {
                        // Navigate to Profile Page
                    })
                    Button("Settings", action: {
                    // Navigate to Settings Page
                })
                } label: {
                Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
            }
               .padding(.horizontal)
                Text("Pending Cases")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                List(cases) { caseItem in
                    CasePreview(caseItem: caseItem) { selected in
                        selectedCase = selected
                    }
                }
            }
            .onAppear {
                fetchPendingCases()
                requestNotificationPermission()
            }
            .alert(isPresented: $showNotification) {
                Alert(
                    title: Text("New Case Assigned"),
                    message: Text(notificationMessage),
                    dismissButton: .default(Text("View Case"), action: {
                        if let firstCase = cases.first {
                            selectedCase = firstCase
                        }
                    })
                )
            }
            .navigationDestination(item: $selectedCase) { caseDetails in
                CaseDetailView(caseDetails: caseDetails)
            }
        }
    }

    func fetchPendingCases() {
        let db = Firestore.firestore()
        db.collection("cases").whereField("status", isEqualTo: "Pending").addSnapshotListener { snapshot, error in
            if let documents = snapshot?.documents, !documents.isEmpty {
                self.cases = documents.map { doc in
                    let data = doc.data()
                    return Case(
                        id: doc.documentID,
                        patientName: data["patientName"] as? String ?? "Unknown",
                        age: data["age"] as? Int ?? 0,
                        medicalHistory: data["medicalHistory"] as? String ?? "No history available",
                        ailment: data["ailment"] as? String ?? "Unknown",
                        aiDiagnosis: data["aiDiagnosis"] as? String ?? "No diagnosis yet",
                        aiFirstAid: data["aiFirstAid"] as? String ?? "No first-aid instructions available",
                        chatHistory: data["chatHistory"] as? [String] ?? [],
                        status: data["status"] as? String ?? "Pending"
                    )
                }
                if let firstCase = cases.first {
                    notificationMessage = "\(firstCase.patientName) needs assistance for \(firstCase.ailment)"
                    showNotification = true
                    sendLocalNotification(message: notificationMessage)
                }
            } else {
                // ✅ **Mock Cases Added**
                self.cases = [
                    Case(id: "1", patientName: "John Doe", age: 34, medicalHistory: "High blood pressure", ailment: "Severe headache", aiDiagnosis: "Possible migraine", aiFirstAid: "Rest and take painkillers", chatHistory: ["Patient: I have a severe headache", "AI: It might be a migraine"], status: "Pending"),
                    Case(id: "2", patientName: "Jane Smith", age: 28, medicalHistory: "Asthma", ailment: "Shortness of breath", aiDiagnosis: "Possible asthma attack", aiFirstAid: "Use inhaler immediately", chatHistory: ["Patient: I am having trouble breathing", "AI: Use your inhaler"], status: "Pending"),
                    Case(id: "3", patientName: "Michael Brown", age: 50, medicalHistory: "Heart disease", ailment: "Chest pain", aiDiagnosis: "Possible heart attack", aiFirstAid: "Seek emergency care immediately", chatHistory: ["Patient: I feel a heavy pain in my chest", "AI: Call 911 now"], status: "Pending"),
                    Case(id: "4", patientName: "Alice Johnson", age: 22, medicalHistory: "No prior conditions", ailment: "Severe allergic reaction", aiDiagnosis: "Anaphylactic shock", aiFirstAid: "Administer epinephrine", chatHistory: ["Patient: My throat is closing up", "AI: Use an EpiPen immediately"], status: "Pending")
                ]
                showNotification = true
                notificationMessage = "Mock cases loaded for testing."
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification Permission Denied: \(error.localizedDescription)")
            }
        }
    }

    func sendLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Case Assigned"
        content.body = message
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

struct Case: Identifiable, Hashable {
    var id: String
    var patientName: String
    var age: Int
    var medicalHistory: String
    var ailment: String
    var aiDiagnosis: String
    var aiFirstAid: String
    var chatHistory: [String]
    var status: String
}

struct CasePreview: View {
    var caseItem: Case
    var onSelect: (Case) -> Void

    var body: some View {
        Button(action: { onSelect(caseItem) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(caseItem.patientName)
                        .font(.headline)
                    Text("AI Diagnosis: \(caseItem.ailment)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct CaseDetailView: View {
    var caseDetails: Case

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button("Release Case") {
                        releaseCase(caseDetails)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }

                Text("Patient: \(caseDetails.patientName), Age: \(caseDetails.age)")
                    .font(.title2)
                    .padding(.bottom, 5)

                Text("Medical History: \(caseDetails.medicalHistory)")
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)

                Text("AI's Initial Diagnosis: \(caseDetails.aiDiagnosis)")
                    .foregroundColor(.blue)
                    .bold()
                    .padding(.bottom, 5)

                Text("First Aid Recommended: \(caseDetails.aiFirstAid)")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)

                Button(action: {}) {
                    HStack {
                        Text("View AI-Patient Chat History")
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }

                HStack(spacing: 20) {
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
                .padding(.top, 15)

                Spacer()
            }
            .padding()
            .navigationTitle("Patient File")
        }
    }

    func releaseCase(_ caseDetails: Case) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseDetails.id).updateData(["status": "Pending", "professionalID": ""])
    }
}

struct ProfessionalHomePage_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalHomePage()
    }
}

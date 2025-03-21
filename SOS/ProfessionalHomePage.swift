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
    @State private var notifiedCaseIDs: Set<String> = []
    @State private var showProfileSheet = false
    @State private var navigateToLogin = false
    @StateObject private var authManager = FirebaseAuthManager()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Menu {
                        Button("Profile", action: {
                            showProfileSheet = true
                        })
                        Button("Settings", action: {
                            // Implement settings navigation as needed
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
                PatientDetailsView(caseDetails: caseDetails, onBack: {
                    // Clear the selected case so we return to ProfessionalHomePage.
                    selectedCase = nil
                })
                .navigationBarBackButtonHidden(true)
            }
            .navigationTitle("Patient Cases")
            .navigationBarBackButtonHidden(true)
            
            NavigationLink(
                destination: AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager),
                isActive: $navigateToLogin
            ) {
                EmptyView()
            }
            .hidden()
            .fullScreenCover(isPresented: $navigateToLogin) {
                AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager)
            }
            .sheet(isPresented: $showProfileSheet) {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.headline)
                    Button("Logout") {
                        authManager.logout()
                        showProfileSheet = false
                        navigateToLogin = true
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Button("Dismiss") {
                        showProfileSheet = false
                    }
                    .padding()
                }
                .padding()
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
                
                if let firstCase = self.cases.first, !notifiedCaseIDs.contains(firstCase.id) {
                    notificationMessage = "\(firstCase.patientName) needs assistance for \(firstCase.ailment)"
                    showNotification = true
                    sendLocalNotification(message: notificationMessage)
                    notifiedCaseIDs.insert(firstCase.id)
                }
            } else {
                self.cases = [
                    Case(id: "1", patientName: "John Doe", age: 34, medicalHistory: "High blood pressure", ailment: "Severe headache", aiDiagnosis: "Possible migraine", aiFirstAid: "Rest and take painkillers", chatHistory: ["Patient: I have a severe headache", "AI: It might be a migraine"], status: "Pending"),
                    Case(id: "2", patientName: "Jane Smith", age: 28, medicalHistory: "Asthma", ailment: "Shortness of breath", aiDiagnosis: "Possible asthma attack", aiFirstAid: "Use inhaler immediately", chatHistory: ["Patient: I am having trouble breathing", "AI: Use your inhaler"], status: "Pending"),
                    Case(id: "3", patientName: "Michael Brown", age: 50, medicalHistory: "Heart disease", ailment: "Chest pain", aiDiagnosis: "Possible heart attack", aiFirstAid: "Seek emergency care immediately", chatHistory: ["Patient: I feel a heavy pain in my chest", "AI: Call 911 now"], status: "Pending"),
                    Case(id: "4", patientName: "Alice Johnson", age: 22, medicalHistory: "No prior conditions", ailment: "Severe allergic reaction", aiDiagnosis: "Anaphylactic shock", aiFirstAid: "Administer epinephrine", chatHistory: ["Patient: My throat is closing up", "AI: Use an EpiPen immediately"], status: "Pending")
                ]
                if !notifiedCaseIDs.contains("mock") {
                    notificationMessage = "Mock cases loaded for testing."
                    showNotification = true
                    notifiedCaseIDs.insert("mock")
                }
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

struct ProfessionalHomePage_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalHomePage()
    }
}

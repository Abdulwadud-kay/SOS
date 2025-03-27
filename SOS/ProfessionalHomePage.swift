


import Foundation
import SwiftUI
import Firebase
import UserNotifications

struct ProfessionalHomePage: View {
    @State private var cases: [Case] = []
    @State private var activePendingCase: Case? = nil
    @State private var showProfileSheet = false
    @State private var navigateToLogin = false
    @StateObject private var authManager = FirebaseAuthManager()
    @State private var listenerRegistration: ListenerRegistration? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button("Profile") { showProfileSheet = true }
                            Button("Settings") { }
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    Text("Recent Cases")
                        .font(.largeTitle)
                        .bold()
                        .padding()

                    LazyVStack(spacing: 10) {
                        ForEach(cases, id: \.self) { caseItem in
                            VStack {
                                CasePreview(caseItem: caseItem) { selected in
                                    activePendingCase = selected
                                }
                                HStack(spacing: 20) {
                                    Button("Accept") {
                                        acceptCase(caseId: caseItem.id, professionalID: authManager.userId)
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.green)
                                    .cornerRadius(8)

                                    Button("Reject") {
                                        rejectCase(caseId: caseItem.id)
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.red)
                                    .cornerRadius(8)

                                    Button("Release") {
                                        releaseCase(caseID: caseItem.id)
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                fetchPendingCases()
                requestNotificationPermission()
            }
            .navigationTitle("Patient Cases")
            .navigationBarBackButtonHidden(true)
            .navigationDestination(item: $activePendingCase) { selectedCase in
                PatientDetailsView(caseID: selectedCase.id, onBack: { activePendingCase = nil })
            }
            .fullScreenCover(isPresented: $navigateToLogin) {
                AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager)
            }
            .sheet(isPresented: $showProfileSheet) {
                VStack(spacing: 20) {
                    Text("Profile").font(.headline)
                    Button("Logout") {
                        authManager.logout()
                        showProfileSheet = false
                        navigateToLogin = true
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Button("Dismiss") { showProfileSheet = false }
                        .padding()
                }
                .padding()
            }
        }
    }

    func acceptCase(caseId: String, professionalID: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseId).updateData([
            "status": "Accepted",
            "professionalID": professionalID
        ]) { err in
            if let err = err { print("Error accepting case: \(err)") }
        }
    }

    func rejectCase(caseId: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseId).updateData([
            "status": "Pending",
            "professionalID": FieldValue.delete()
        ]) { err in
            if let err = err { print("Error rejecting case: \(err)") }
        }
    }

    func releaseCase(caseID: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseID).updateData([
            "status": "Pending",
            "professionalID": FieldValue.delete()
        ]) { err in
            if let err = err { print("Error releasing case: \(err.localizedDescription)") }
            else { dismiss() }
        }
    }
}

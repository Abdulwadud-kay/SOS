


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
                            CasePreview(caseItem: caseItem) { selected in
                                activePendingCase = selected
                            }
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
                PatientDetailsView(caseDetails: selectedCase) {
                    activePendingCase = nil
                }
            }
            
            NavigationLink(
                destination: AuthenticationPage(
                    isAuthenticated: $authManager.isAuthenticated,
                    authManager: authManager
                ),
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
        listenerRegistration = db.collection("cases")
            .whereField("status", isEqualTo: "Pending")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching pending cases: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    self.cases = []
                    return
                }
                self.cases = documents.map { doc in
                    let data = doc.data()
                    return Case(
                        id: doc.documentID,
                        patientName: data["patientName"] as? String ?? "Unknown",
                        age: data["age"] as? Int ?? 0,
                        medicalHistory: data["medicalHistory"] as? String ?? "",
                        chatHistory: data["chatHistory"] as? [String] ?? [],
                        status: data["status"] as? String ?? "Pending"
                    )
                }
            }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func acceptCase(_ pendingCase: Case) {
        let db = Firestore.firestore()
        let professionalID = authManager.userId
        db.collection("cases").document(pendingCase.id).updateData([
            "status": "Accepted",
            "professionalID": professionalID
        ]) { err in
            if let err = err {
                print("Error accepting case: \(err)")
            } else {
                activePendingCase = pendingCase
            }
        }
    }
    
    func rejectCase(_ pendingCase: Case) {
        activePendingCase = nil
    }
}

struct ProfessionalHomePage_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalHomePage()
    }
}

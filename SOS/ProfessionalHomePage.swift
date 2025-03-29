


import SwiftUI
import Firebase
import UserNotifications

struct ProfessionalHomePage: View {
    @State private var cases: [Case] = []
    @State private var activePendingCase: Case? = nil
    @State private var showProfileSheet = false
    @State private var showSettings = false
    @State private var navigateToLogin = false
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var listenerRegistration: ListenerRegistration? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingCaseAlert = false
    @State private var selectedCaseID: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                MedicalPatternBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            HStack(spacing: 4) {
                                Text("SOS")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Button {
                                showProfileSheet = true
                            } label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                        Divider()
                            .padding(.horizontal)
                            .padding(.bottom, 4)

//i need a line after here to seperate the sos and profile icon hstack from the next thing below the page.
                        LazyVStack(spacing: 14) {
                            ForEach(cases, id: \.self) { caseItem in
                                VStack(alignment: .leading, spacing: 8) {
                                    CasePreview(caseItem: caseItem) { selected in
                                        if caseItem.status == "Pending" {
                                            selectedCaseID = selected.id
                                            showingCaseAlert = true
                                        } else {
                                            activePendingCase = selected
                                        }
                                    }

                                    if caseItem.status == "Accepted" && caseItem.id == selectedCaseID {
                                        Button("Release") {
                                            releaseCase(caseID: caseItem.id)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Patient Cases")
            .navigationBarBackButtonHidden(true)
            .navigationDestination(item: $activePendingCase) { selectedCase in
                PatientDetailsView(caseID: selectedCase.id, onBack: { activePendingCase = nil })
            }
            .fullScreenCover(isPresented: .constant(!authManager.isAuthenticated)) {
                AuthenticationPage(isAuthenticated: $authManager.isAuthenticated)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileSheetView(onClose: {
                    showProfileSheet = false
                })
                .environmentObject(authManager)
            }

            .alert("New Case Request", isPresented: $showingCaseAlert) {
                Button("Accept") {
                    if let caseID = selectedCaseID {
                        acceptCase(caseId: caseID, professionalID: authManager.userId)
                        showingCaseAlert = false
                    }
                }
                Button("Reject", role: .destructive) {
                    if let caseID = selectedCaseID {
                        rejectCase(caseId: caseID)
                        showingCaseAlert = false
                    }
                }
                Button("Cancel", role: .cancel) {
                    showingCaseAlert = false
                }
            } message: {
                Text("Do you want to accept this case?")
            }
            .onAppear {
                fetchPendingCases()
                requestNotificationPermission()
            }
            .onDisappear {
                listenerRegistration?.remove()
            }
        }
    }

    // MARK: - Firestore Logic

    func fetchPendingCases() {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching cases: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.cases = []
                    return
                }

                self.cases = documents.compactMap { doc in
                    let data = doc.data()
                    let rejected = data["rejectedBy"] as? [String] ?? []
                    let assigned = data["professionalID"] as? String ?? ""

                    if rejected.contains(authManager.userId) {
                        return nil
                    }

                    if data["status"] as? String == "Pending" || assigned == authManager.userId {
                        return Case(
                            id: doc.documentID,
                            patientName: data["patientName"] as? String ?? "Unknown",
                            age: data["age"] as? Int ?? 0,
                            medicalHistory: data["medicalHistory"] as? String ?? "",
                            chatHistory: data["chatHistory"] as? [String] ?? [],
                            status: data["status"] as? String ?? "Pending",
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    return nil
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

    func acceptCase(caseId: String, professionalID: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseId).updateData([
            "status": "Accepted",
            "professionalID": professionalID
        ]) { err in
            if let err = err {
                print("Error accepting case: \(err)")
            } else {
                selectedCaseID = caseId
                activePendingCase = cases.first(where: { $0.id == caseId })
            }
        }
    }

    func rejectCase(caseId: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseId).updateData([
            "rejectedBy": FieldValue.arrayUnion([authManager.userId])
        ]) { err in
            if let err = err {
                print("Error rejecting case: \(err)")
            } else {
                print("🚫 Case \(caseId) rejected by \(authManager.userId)")
            }
        }
    }

    func releaseCase(caseID: String) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseID).updateData([
            "status": "Pending",
            "professionalID": FieldValue.delete()
        ]) { err in
            if let err = err {
                print("Error releasing case: \(err.localizedDescription)")
            } else {
                dismiss()
            }
        }
    }
}

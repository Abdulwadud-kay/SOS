

// File: HomePage.swift

import SwiftUI
import UIKit
import AVFoundation
import Speech
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct MedicalPatternBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let icons = ["cross.case", "bandage.fill", "syringe.fill", "stethoscope", "car.fill"]
            let size = geometry.size

            ZStack {
                Color(UIColor.systemBackground)

                ForEach(0..<40, id: \.self) { _ in
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let icon = icons.randomElement() ?? "cross.case"

                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.gray)
                        .opacity(0.06)
                        .position(x: x, y: y)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct HomePage: View { 
    var incomingCaseID: String? = nil
    @State private var messages: [String] = []
    @State private var currentMessage: String = ""
    @State private var showSpeechSheet = false
    @State private var showCameraSheet = false
    @State private var showProfileSheet = false
    @State private var transcribedText: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedTab = 0
    @State private var requestingProfessionalHelp = false
    @State private var navigateToLogin = false
    @State private var isWaitingForResponse = false
    @State private var caseID: String? = nil
    @State private var listenerRegistration: ListenerRegistration? = nil
    @State private var hasActiveCase = false
    @State private var currentCaseStatus: String = "InProgress"
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var authManager = FirebaseAuthManager()
    private let chatGPTService = ChatGPTService()
    
    var isRequestHelpEnabled: Bool {
        return currentCaseStatus == "Pending" || currentCaseStatus == "InProgress"
    }
    var isCloseCaseEnabled: Bool {
        return currentCaseStatus != "Closed" && currentCaseStatus != "Resolved"
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ZStack {
                    MedicalPatternBackground()
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            HStack(spacing: 4) {
                                Text("SOS")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Image("Logo")
                                    .resizable()
                                    .frame(width: 20, height: 20)
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

                        // Case Controls
                        HStack(spacing: 16) {
                            Button(action: requestProfessionalHelp) {
                                Text("Request Professional Help")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(currentCaseStatus == "Pending" || currentCaseStatus == "InProgress" ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(!(currentCaseStatus == "Pending" || currentCaseStatus == "InProgress"))

                            Button(action: closeCase) {
                                Text("Close Case")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(currentCaseStatus != "Closed" && currentCaseStatus != "Resolved" ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(currentCaseStatus == "Closed" || currentCaseStatus == "Resolved")
                        }
                        .padding(.horizontal)

                        if requestingProfessionalHelp {
                            Text("Finding the best professional for you...")
                                .foregroundColor(.gray)
                                .padding(.bottom)
                        }

                        // Chat Area
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(messages, id: \.self) { message in
                                    HStack(alignment: .top) {
                                        if message.hasPrefix("User:") {
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Text(message.replacingOccurrences(of: "User:", with: ""))
                                                    .padding()
                                                    .foregroundColor(.white)
                                                    .background(Color.blue)
                                                    .cornerRadius(12)
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        } else if message.hasPrefix("GPT:") {
                                            HStack(spacing: 4) {
                                                Image(systemName: "cross.case")
                                                    .foregroundColor(.green)
                                                Text(message.replacingOccurrences(of: "GPT:", with: ""))
                                                    .padding()
                                                    .foregroundColor(.black)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(12)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal)
                                }

                                if isWaitingForResponse {
                                    LoadingDotsView()
                                        .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .onTapGesture { hideKeyBoard() }

                        // Input Bar
                        HStack(spacing: 10) {
                            TextField("Type a message...", text: $currentMessage)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Button(action: { showCameraSheet = true }) {
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 8)
                                        }
                                        Button(action: {
                                            showSpeechSheet = true
                                            speechRecognizer.startTranscribing { text in
                                                transcribedText = text
                                            }
                                        }) {
                                            Image(systemName: "mic.fill")
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 8)
                                        }
                                    }
                                )

                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.red)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        Divider()
                            .background(Color.gray.opacity(0.4))
                    }
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                RecentsPage()
                    .tabItem {
                        Label("Recents", systemImage: "clock.fill")
                    }
                    .tag(1)
            }

            .sheet(isPresented: $showSpeechSheet) {
                SpeechRecognitionView(transcribedText: $transcribedText, onSend: {
                    if !transcribedText.trimmingCharacters(in: .whitespaces).isEmpty {
                        currentMessage = transcribedText.trimmingCharacters(in: .whitespaces)
                        sendMessage()
                        transcribedText = ""
                    }
                    showSpeechSheet = false
                })
            }

            .sheet(isPresented: $showCameraSheet) {
                CameraView { recognizedText in
                    isWaitingForResponse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !recognizedText.trimmingCharacters(in: .whitespaces).isEmpty {
                            currentMessage = recognizedText
                            sendMessage()
                        }
                        isWaitingForResponse = false
                    }
                }
            }

            .sheet(isPresented: $showProfileSheet) {
                ProfileSheetView(authManager: authManager, onClose: {
                    showProfileSheet = false
                })
            }


            .fullScreenCover(isPresented: .constant(!authManager.isAuthenticated)) {
                AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager)
            }

            .onAppear {
                if let existingID = incomingCaseID {
                    caseID = existingID
                    hasActiveCase = true
                    listenToCaseDocument(docId: existingID)
                } else {
                    autoCreateCaseIfNotExists()
                }
            }
            .onDisappear { listenerRegistration?.remove() }
        }
    }
    
    func fetchQuestionnaire(for userID: String, completion: @escaping ([Any]?) -> Void) {
        let db = Firestore.firestore()
        db.collection("questionnaires").document(userID).getDocument { snap, err in
            if let data = snap?.data(), let arr = data["answers"] as? [Any] {
                completion(arr)
            } else {
                completion(nil)
            }
        }
    }
    
    func extractAnswer(_ answers: [Any], index: Int) -> String? {
        guard index < answers.count else { return nil }
        if let map = answers[index] as? [String: Any], let val = map.values.first as? String {
            return val
        }
        return nil
    }

    
    func autoCreateCaseIfNotExists() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        db.collection("cases")
            .whereField("patientUid", isEqualTo: user.uid)
            .whereField("status", isNotEqualTo: "Closed")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    self.caseID = docs.first?.documentID
                    self.hasActiveCase = true
                    self.listenToCaseDocument(docId: self.caseID!)
                    return
                }

                db.collection("questionnaire").document(user.uid).getDocument { snap, err in
                    guard let data = snap?.data(),
                          let answers = data["answers"] as? [[String: String]] else {
                        print("⚠️ No questionnaire data found")
                        return
                    }

                    // Extract and format data
                    let name = answers.first?["What is your full name?"] ?? user.displayName ?? "Unknown"
                    let birthDate = answers[1]["When were you born?"] ?? ""
                    let age = calculateAge(from: birthDate) ?? 0
                    let medHistory = answers
                        .dropFirst(2)
                        .compactMap { $0.values.first }
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n")

                    // Create case
                    let ref = db.collection("cases").document()
                    let caseData: [String: Any] = [
                        "patientUid": user.uid,
                        "patientName": name,
                        "age": age,
                        "medicalHistory": medHistory,
                        "chatHistory": [],
                        "status": "InProgress",
                        "createdAt": FieldValue.serverTimestamp()
                    ]

                    ref.setData(caseData) { error in
                        if let error = error {
                            print("❌ Failed to create case: \(error)")
                            return
                        }
                        self.caseID = ref.documentID
                        self.hasActiveCase = true
                        self.listenToCaseDocument(docId: ref.documentID)
                    }
                }
            }
    }



    
    func listenToCaseDocument(docId: String) {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases").document(docId)
            .addSnapshotListener { snap, err in
                DispatchQueue.main.async {
                    if let err = err {
                        print("Error: \(err)")
                        return
                    }

                    guard let d = snap?.data() else { return }

                    caseID = docId
                    messages = d["chatHistory"] as? [String] ?? []
                    currentCaseStatus = d["status"] as? String ?? "InProgress"
                    requestingProfessionalHelp = currentCaseStatus == "Pending"
                    hasActiveCase = ["InProgress", "Pending", "Accepted"].contains(currentCaseStatus)
                }
            }
    }

    
    func requestProfessionalHelp() {
        requestingProfessionalHelp = true
        guard let user = Auth.auth().currentUser, let docId = caseID else {
            print("No case doc to update.")
            requestingProfessionalHelp = false
            return
        }
        let db = Firestore.firestore()

        fetchQuestionnaire(for: user.uid) { answers in
            let name = extractAnswer(answers ?? [], index: 0) ?? (user.displayName ?? "Unknown")

            // ✅ Calculate age from birthdate
            let birthdateISO = extractAnswer(answers ?? [], index: 1) ?? ""
            let age = calculateAge(from: birthdateISO)

            // ✅ Build medical history with labels
            let prompts = [
                "Gender", "Blood Type", "Allergies", "Chronic Conditions", "Past Surgeries",
                "Medications", "Do you smoke?", "Do you consume alcohol?",
                "Emergency Contact Name", "Emergency Contact Number", "Current Health Concern"
            ]
            var medHist = ""
            if let arr = answers {
                for (i, label) in prompts.enumerated() {
                    if let val = extractAnswer(arr, index: i + 2), !val.isEmpty {
                        medHist += "\(label): \(val)\n"
                    }
                }
            }

            let updateData: [String: Any] = [
                "patientName": name,
                "age": age,
                "medicalHistory": medHist,
                "status": "Pending"
            ]

            db.collection("cases").document(docId).updateData(updateData) { err in
                requestingProfessionalHelp = false
                if let err = err {
                    print("Error updating case to Pending: \(err)")
                    return
                }
                print("✅ Case \(docId) is now Pending.")
            }
        }
    }

    
    func closeCase() {
        guard let docId = caseID else {
            print("No open case to close.")
            return
        }
        let db = Firestore.firestore()
        db.collection("cases").document(docId).updateData([
            "status": "Closed"
        ]) { err in
            if let err = err {
                print("Error closing case: \(err)")
                return
            }
            print("Case \(docId) has been closed.")
            hasActiveCase = false
            caseID = nil
            messages = []
            autoCreateCaseIfNotExists()
        }
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let msg = currentMessage.trimmingCharacters(in: .whitespaces)
        currentMessage = ""
        hideKeyBoard()
        guard let did = caseID else {
            print("No case doc.")
            return
        }
        let db = Firestore.firestore()
        let userMsg = "User: \(msg)"
        db.collection("cases").document(did).updateData([
            "chatHistory": FieldValue.arrayUnion([userMsg])
        ]) { err in
            if let err = err {
                print("Error saving user msg: \(err)")
                return
            }
            isWaitingForResponse = true
            db.collection("cases").document(did).getDocument { snap, error in
                guard error == nil, let docData = snap?.data(),
                      let full = docData["chatHistory"] as? [String] else {
                    print("No updated chatHistory.")
                    return
                }
                var chatMsgs: [ChatGPTMessage] = []
                for item in full {
                    if item.hasPrefix("User:") {
                        let c = item.replacingOccurrences(of: "User:", with: "").trimmingCharacters(in: .whitespaces)
                        chatMsgs.append(ChatGPTMessage(role: "user", content: c))
                    } else if item.hasPrefix("GPT:") {
                        let c = item.replacingOccurrences(of: "GPT:", with: "").trimmingCharacters(in: .whitespaces)
                        chatMsgs.append(ChatGPTMessage(role: "assistant", content: c))
                    }
                }

                // Decide if you want GPT-4 or GPT-3.5:
                let wantGPT4 = true  // or maybe false

                chatGPTService.sendMessageToChatGPT(messages: chatMsgs, useGPT4: wantGPT4) { result in
                    DispatchQueue.main.async {
                        self.isWaitingForResponse = false
                        switch result {
                        case .success(let reply):
                            let gptMsg = "GPT: \(reply)"
                            db.collection("cases").document(did).updateData([
                                "chatHistory": FieldValue.arrayUnion([gptMsg])
                            ])
                        case .failure(let e):
                            print("ChatGPT error: \(e)")
                        }
                    }
                }

            }
        }
    }
    
    func buildChatGPTMessages() -> [ChatGPTMessage] {
        var chatM: [ChatGPTMessage] = []
        let recentMessages = messages.suffix(8) // Corrected to 'messages'
        for i in recentMessages {
            if i.hasPrefix("User:") {
                let c = i.replacingOccurrences(of: "User:", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
                chatM.append(ChatGPTMessage(role: "user", content: c))
            } else if i.hasPrefix("GPT:") {
                let c = i.replacingOccurrences(of: "GPT:", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
                chatM.append(ChatGPTMessage(role: "assistant", content: c))
            }
        }
        return chatM
    }
    
    func calculateAge(from isoDate: String) -> Int {
        guard let birthDate = ISO8601DateFormatter().date(from: isoDate) else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }




    
    func formatDiagnosis(response: String) -> String {
        "GPT: \n-----------------\n\(response)\n-----------------"
    }
    
    func hideKeyBoard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func extractJSON(from text: String) -> String? {
        guard let s = text.firstIndex(of: "{"),
              let e = text.lastIndex(of: "}") else {
            return nil
        }
        return String(text[s...e])
    }
}

struct HomePageWithLoad: View {
    let caseID: String
    var body: some View {
        HomePage(incomingCaseID: caseID)
    }
}

struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}

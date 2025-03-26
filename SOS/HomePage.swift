


import SwiftUI
import UIKit
import AVFoundation
import Speech
import Firebase
import FirebaseFirestore
import FirebaseAuth

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
    @State private var showClarification = false
    @State private var clarificationQuestion: String = ""
    @State private var clarificationOptions: [ClarificationItem] = []
    @State private var finalDiagnosis: String? = nil
    @State private var isWaitingForResponse = false
    @State private var caseID: String? = nil
    @State private var listenerRegistration: ListenerRegistration? = nil
    @State private var hasActiveCase = false
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var authManager = FirebaseAuthManager()
    private let chatGPTService = ChatGPTService()
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ZStack {
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
                        
                        if hasActiveCase {
                            Button(action: closeCase) {
                                Text("Close Case")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding()
                            }
                        } else {
                            Button(action: requestProfessionalHelp) {
                                Text("Request Professional Help")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding()
                            }
                        }
                        
                        if requestingProfessionalHelp {
                            Text("Finding the best professional for you...")
                                .foregroundColor(.gray)
                                .padding(.bottom)
                        }
                        
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
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                showSpeechSheet = true
                                speechRecognizer.startTranscribing { text in
                                    transcribedText = text
                                }
                            }) {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.gray)
                            }
                            TextField("Type your message...", text: $currentMessage)
                                .frame(minHeight: 40)
                            Button(action: { showCameraSheet = true }) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.gray)
                            }
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Color.white.edgesIgnoringSafeArea(.bottom))
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
                
                RecentsPage()
                    .tabItem { Label("Recents", systemImage: "clock.fill") }
                    .tag(1)
            }
            
            NavigationLink(
                destination: AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager),
                isActive: $navigateToLogin
            ) {
                EmptyView()
            }
            .hidden()
            
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
                CameraView(selectedImages: $selectedImages)
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
            
            .sheet(isPresented: $showClarification) {
                ClarificationReplyView(question: clarificationQuestion, options: clarificationOptions) { chosen in
                    let clarText = chosen.map { $0.text }.joined(separator: ", ")
                    let clarMsg = "User (clarification): \(clarText)"
                    messages.append(clarMsg)
                    showClarification = false
                    getDiagnosis()
                }
            }
            .onAppear { autoCreateCaseIfNotExists() }
            .onDisappear { listenerRegistration?.remove() }
            .navigationBarBackButtonHidden(true)
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
            .whereField("status", in: ["Pending", "InProgress"])
            .getDocuments { snap, error in
                if let error = error {
                    print("Error checking existing case: \(error)")
                    return
                }
                if let docs = snap?.documents, !docs.isEmpty {
                    let d = docs.first!
                    caseID = d.documentID
                    listenToCaseDocument(docId: d.documentID)
                    hasActiveCase = true
                } else {
                    fetchQuestionnaire(for: user.uid) { answers in
                        let name = extractAnswer(answers ?? [], index: 0) ?? (user.displayName ?? "Unknown")
                        let age = 0
                        var medHist = ""
                        if let arr = answers {
                            for (i, _) in arr.enumerated() {
                                if i != 0 {
                                    if let str = extractAnswer(arr, index: i), !str.isEmpty {
                                        medHist += str + "\n"
                                    }
                                }
                            }
                        }
                        let ref = db.collection("cases").document()
                        let data: [String: Any] = [
                            "patientUid": user.uid,
                            "patientName": name,
                            "age": age,
                            "medicalHistory": medHist,
                            "chatHistory": [],
                            "status": "InProgress",
                            "createdAt": FieldValue.serverTimestamp()
                        ]
                        ref.setData(data) { err in
                            if let err = err {
                                print("Error creating new case: \(err)")
                                return
                            }
                            caseID = ref.documentID
                            listenToCaseDocument(docId: ref.documentID)
                            hasActiveCase = true
                        }
                    }
                }
            }
    }
    
    func listenToCaseDocument(docId: String) {
        let db = Firestore.firestore()
        listenerRegistration = db.collection("cases").document(docId)
            .addSnapshotListener { snap, err in
                if let err = err {
                    print("Error listening to doc: \(err)")
                    return
                }
                guard let d = snap?.data() else {
                    print("No data found for case \(docId).")
                    return
                }
                if let arr = d["chatHistory"] as? [String] {
                    messages = arr
                }
                if let st = d["status"] as? String {
                    requestingProfessionalHelp = (st == "Pending")
                    hasActiveCase = (st == "InProgress" || st == "Pending")
                }
            }
    }
    
    func requestProfessionalHelp() {
        requestingProfessionalHelp = true
        guard let docId = caseID else {
            print("No case doc to set as Pending.")
            requestingProfessionalHelp = false
            return
        }
        let db = Firestore.firestore()
        db.collection("cases").document(docId).updateData([
            "status": "Pending"
        ]) { err in
            if let err = err {
                print("Error setting Pending: \(err)")
                requestingProfessionalHelp = false
                return
            }
            print("Case doc \(docId) is now Pending.")
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
                chatGPTService.sendMessageToChatGPT(messages: chatMsgs) { result in
                    DispatchQueue.main.async {
                        isWaitingForResponse = false
                        switch result {
                        case .success(let reply):
                            if let block = extractJSON(from: reply),
                               let jData = block.data(using: .utf8),
                               let jObj = try? JSONSerialization.jsonObject(with: jData) as? [String: Any],
                               let quest = jObj["question"] as? String,
                               let opts = jObj["options"] as? [String] {
                                clarificationQuestion = quest
                                clarificationOptions = opts.map { ClarificationItem(text: $0) }
                                showClarification = true
                            } else {
                                let gptMsg = "GPT: \(reply)"
                                db.collection("cases").document(did).updateData([
                                    "chatHistory": FieldValue.arrayUnion([gptMsg])
                                ])
                            }
                        case .failure(let e):
                            print("ChatGPT error: \(e)")
                        }
                    }
                }
            }
        }
    }
    
    func getDiagnosis() {
        guard let did = caseID else { return }
        let db = Firestore.firestore()
        isWaitingForResponse = true
        chatGPTService.sendMessageToChatGPT(messages: buildChatGPTMessages()) { res in
            DispatchQueue.main.async {
                isWaitingForResponse = false
                switch res {
                case .success(let r):
                    finalDiagnosis = r
                    let fm = formatDiagnosis(response: r)
                    db.collection("cases").document(did).updateData([
                        "chatHistory": FieldValue.arrayUnion([fm])
                    ])
                case .failure(let e):
                    print("ChatGPT error: \(e)")
                }
            }
        }
    }
    
    func buildChatGPTMessages() -> [ChatGPTMessage] {
        var chatM: [ChatGPTMessage] = []
        for i in messages {
            if i.hasPrefix("User:") {
                let c = i.replacingOccurrences(of: "User:", with: "").trimmingCharacters(in: .whitespaces)
                chatM.append(ChatGPTMessage(role: "user", content: c))
            } else if i.hasPrefix("GPT:") {
                let c = i.replacingOccurrences(of: "GPT:", with: "").trimmingCharacters(in: .whitespaces)
                chatM.append(ChatGPTMessage(role: "assistant", content: c))
            }
        }
        return chatM
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




struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}

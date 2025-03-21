import SwiftUI
import UIKit
import AVFoundation
import Speech

struct HomePage: View {
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

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var authManager = FirebaseAuthManager()
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ZStack {
                    VStack {
                        // Top menu with Profile and Settings
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
                        
                        // Request Professional Help button
                        Button(action: {
                            requestingProfessionalHelp = true
                            findMatchingProfessional()
                        }) {
                            Text("Request Professional Help")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding()
                        }
                        
                        if requestingProfessionalHelp {
                            Text("Finding the best professional for you...")
                                .foregroundColor(.gray)
                                .padding(.bottom)
                        }
                        
                        // Chat messages view
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(messages, id: \.self) { message in
                                    HStack {
                                        if isUserMessage(message) {
                                            Spacer()
                                            Text(message)
                                                .padding()
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .cornerRadius(12)
                                        } else {
                                            Text(message)
                                                .padding()
                                                .foregroundColor(.black)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(12)
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .onTapGesture {
                            hideKeyBoard()
                        }
                        
                        // Input area for chat
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
                            Button(action: {
                                showCameraSheet = true
                            }) {
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
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                PastDiagnosisPage()
                    .tabItem {
                        Label("Past Diagnosis", systemImage: "clock.fill")
                    }
                    .tag(1)
            }
            // Hidden NavigationLink for logout navigation:
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
                        messages.append(transcribedText.trimmingCharacters(in: .whitespaces))
                        currentMessage = transcribedText.trimmingCharacters(in: .whitespaces)
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
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func isUserMessage(_ text: String) -> Bool {
        return !text.contains("AI offline") && !text.contains("GPT-4 Turbo")
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let message = currentMessage.trimmingCharacters(in: .whitespaces)
        messages.append(message)
        currentMessage = ""
        hideKeyBoard()
        fetchGPTResponse(for: message)
    }
    
    func fetchGPTResponse(for userInput: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let random = Bool.random()
            if random {
                messages.append("GPT-4 Turbo: This is a mocked AI response to \"\(userInput)\"")
            } else {
                messages.append("AI offline")
            }
        }
    }
    
    func findMatchingProfessional() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            requestingProfessionalHelp = false
            messages.append("AI: A professional has been assigned to you. They will review your case shortly.")
        }
    }
    
    func hideKeyBoard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
        
}

struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}

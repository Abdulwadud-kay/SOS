



import SwiftUI
import UIKit
import AVFoundation
import Speech

struct HomePage: View {
    @State private var messages: [String] = []
    @State private var currentMessage: String = ""
    @State private var showMicScreen = false
    @State private var showCameraScreen = false
    @State private var showBeatingCircle = false
    @State private var transcribedText: String = ""
    @State private var capturedImage: UIImage? = nil
    @State private var selectedTab = 0
    @State private var requestingProfessionalHelp = false

    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ZStack {
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
                    // REQUEST PROFESSIONAL HELP
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
                    
                    // Normal chat UI continues here...
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
                    
                    // Input Area
                    HStack(spacing: 10) {
                        Button(action: {
                            showMicScreen = true
                            showBeatingCircle = true
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
                            showCameraScreen = true
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
    }
    
    func isUserMessage(_ text: String) -> Bool {
        !text.contains("AI offline") && !text.contains("GPT-4 Turbo")
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

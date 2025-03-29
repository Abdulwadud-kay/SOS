//
//  SpeechRecognitionView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/21/25.
//


import SwiftUI

struct SpeechRecognitionView: View {
    @Binding var transcribedText: String
    var onSend: () -> Void
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Blurred background
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Mic with pulse
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: animate ? 120 : 100, height: animate ? 120 : 100)
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)

                    Circle()
                        .fill(Color.red)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
                .onAppear { animate = true }

                // Live transcript
                Text(transcribedText.isEmpty ? "Listening..." : "\"\(transcribedText)\"")
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)

                // Send button
                Button(action: onSend) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

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
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                TextField("Speak now...", text: $transcribedText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send", action: onSend)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }
}

struct SpeechRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechRecognitionView(transcribedText: .constant(""), onSend: {})
    }
}

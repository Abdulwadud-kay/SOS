//
//  ClarificationView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/3/25.
//

import Foundation
import SwiftUI

struct ClarificationItem: Identifiable {
    let id = UUID()
    let text: String
}

struct ClarificationReplyView: View {
    var question: String
    var options: [ClarificationItem]
    var onSubmit: ([ClarificationItem]) -> Void

    @State private var selectedItems: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.headline)

            ForEach(options) { item in
                Button(action: {
                    toggleSelection(item)
                }) {
                    HStack {
                        Text(item.text)
                        Spacer()
                        if selectedItems.contains(item.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            Button(action: {
                let chosen = options.filter { selectedItems.contains($0.id) }
                onSubmit(chosen)
            }) {
                Text("Submit")
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(selectedItems.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
            }
            .disabled(selectedItems.isEmpty)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    func toggleSelection(_ item: ClarificationItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }
}

struct ClarificationReplyView_Previews: PreviewProvider {
    static var previews: some View {
        // Simulate an AI deciding the question and options.
        let aiQuestion = "Which of the following best describes your issue?"
        let aiOptions = [
            ClarificationItem(text: "Mild headache"),
            ClarificationItem(text: "Severe headache"),
            ClarificationItem(text: "Fatigue"),
            ClarificationItem(text: "Other")
        ]
        return ClarificationReplyView(
            question: aiQuestion,
            options: aiOptions
        ) { chosen in
            // handle chosen
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

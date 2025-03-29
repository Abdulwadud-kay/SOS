//
//  Case.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/21/25.
//


import SwiftUI

struct Case: Identifiable, Hashable {
    var id: String
    var patientName: String
    var age: Int
    var medicalHistory: String
    var chatHistory: [String]
    var status: String
    var createdAt: Date
}

struct CasePreview: View {
    var caseItem: Case
    var onSelect: (Case) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: { onSelect(caseItem) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseItem.patientName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Status: \(caseItem.status)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
            )
        }
    }
}

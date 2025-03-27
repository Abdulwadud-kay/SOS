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

    var body: some View {
        Button(action: { onSelect(caseItem) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(caseItem.patientName)
                        .font(.headline)
                    // Remove or replace the line below, for example:
                    // Text("Status: \(caseItem.status)")
                    Text("Status: \(caseItem.status)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

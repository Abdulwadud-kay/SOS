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
    var ailment: String
    var aiDiagnosis: String
    var aiFirstAid: String
    var chatHistory: [String]
    var status: String
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
                    Text("AI Diagnosis: \(caseItem.ailment)")
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
